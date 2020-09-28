// SPDX-License-Identifier: 0BSD
const Builder = @import("std").build.Builder;

pub fn build(b: *Builder) void {
    const mode = b.standardReleaseOptions();
    const target = b.standardTargetOptions(.{});
    b.top_level_steps.shrinkRetainingCapacity(0);

    const test_filter = b.option([]const u8, "test-filter", "Filter the tests to be run.");
    const main_tests = b.addTest("src/tests.zig");
    main_tests.setFilter(test_filter);
    main_tests.setBuildMode(mode);

    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&main_tests.step);

    b.default_step = test_step;
}
