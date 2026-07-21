#!/usr/bin/env bash

set -euo pipefail

readonly LOG_FILE=/tmp/beetle-saturn-build.log
exec > >(tee "${LOG_FILE}") 2>&1
trap 'exit_status=$?; if [ "${exit_status}" -ne 0 ]; then echo "Beetle Saturn linker diagnostics:"; grep -E "wasm-ld: error:|undefined symbol|duplicate symbol" "${LOG_FILE}" || true; echo "Beetle Saturn build failed; final log lines:"; tail -n 80 "${LOG_FILE}"; fi' EXIT

readonly CORE_SOURCE_DIR=/src/beetle-saturn-libretro
readonly RETROARCH_DIR=/src/RetroArch
readonly RETROARCH_EJS_DIR="${RETROARCH_DIR}/emulatorjs"
readonly EJS_OUTPUT_DIR=/src/EmulatorJS/data/cores
readonly OUTPUT_DIR=/output/cores
readonly CORE_VERSION="${BEETLE_SATURN_COMMIT:?BEETLE_SATURN_COMMIT is required}"

# Emscripten's sysroot does not expose a system zlib installation. Build the
# vendored zlib instead of the Makefile's native-platform default.
emmake make -C "${CORE_SOURCE_DIR}" platform=emscripten SYSTEM_ZLIB=0

mkdir -p "${RETROARCH_EJS_DIR}" "${EJS_OUTPUT_DIR}"
cp "${CORE_SOURCE_DIR}/mednafen_saturn_libretro_emscripten.bc" \
  "${RETROARCH_EJS_DIR}/"

for build_args in "" "--threads" "--legacy" "--threads --legacy"; do
  # shellcheck disable=SC2086
  (
    cd "${RETROARCH_EJS_DIR}"
    emmake ./build-emulatorjs.sh ${build_args}
  )
done

for core_archive in "${EJS_OUTPUT_DIR}"/mednafen_saturn*-wasm.data; do
  core_payload_dir="$(mktemp -d)"
  7z x -y "${core_archive}" "-o${core_payload_dir}" >/dev/null

  cat >"${core_payload_dir}/core.json" <<'EOF'
{"name":"mednafen_saturn","extensions":["cue","toc","m3u","ccd","chd"],"makeoptions":{"arguments":[],"buildpath":"./","makescript":"Makefile"},"options":{},"save":"srm","license":"COPYING","repo":"https://github.com/libretro/beetle-saturn-libretro"}
EOF
  cat >"${core_payload_dir}/build.json" <<'EOF'
{"minimumEJSVersion":"4.2.2","version":"2.0.2"}
EOF
  cp "${CORE_SOURCE_DIR}/COPYING" "${core_payload_dir}/license.txt"

  rm "${core_archive}"
  (
    cd "${core_payload_dir}"
    7z a -t7z "${core_archive}" . >/dev/null
  )
  rm -rf "${core_payload_dir}"
done

mkdir -p "${OUTPUT_DIR}/reports"
cp "${EJS_OUTPUT_DIR}"/mednafen_saturn*-wasm.data "${OUTPUT_DIR}/"
printf '{"core":"mednafen_saturn","buildStart":"%s","buildEnd":"%s","options":{}}\n' \
  "${CORE_VERSION}" "${CORE_VERSION}" >"${OUTPUT_DIR}/reports/mednafen_saturn.json"
