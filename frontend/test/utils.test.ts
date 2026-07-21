import { describe, expect, it } from "vitest";
import {
  getSupportedEJSCores,
  languageToEmoji,
  regionToEmoji,
} from "@/utils";

describe("regionToEmoji", () => {
  it("does not render Public Domain as the Poland flag", () => {
    expect(regionToEmoji("PD")).toBe("PD");
    expect(regionToEmoji("Public Domain")).toBe("Public Domain");
  });
});

describe("languageToEmoji", () => {
  it("keeps the Polish language flag mapping", () => {
    expect(languageToEmoji("PL")).toBe("🇵🇱");
    expect(languageToEmoji("Polish")).toBe("🇵🇱");
  });
});

describe("getSupportedEJSCores", () => {
  it("prefers the Mednafen Saturn fallback while retaining Yabause", () => {
    expect(getSupportedEJSCores("saturn")).toEqual([
      "mednafen_saturn",
      "yabause",
    ]);
  });
});
