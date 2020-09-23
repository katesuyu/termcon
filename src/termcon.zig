// SPDX-License-Identifier: 0BSD
pub const style = @import("style.zig");
pub const ansi = @import("ansi.zig");
pub const device = @import("device.zig");

comptime {
    @import("std").meta.refAllDecls(@This());
}
