// SPDX-License-Identifier: MIT
// Copyright (c) 2015-2020 Zig Contributors
// This file is part of [zig](https://ziglang.org/), which is MIT licensed.
// The MIT license requires this copyright notice to be included in all copies
// and substantial portions of the software.
const std = @import("std");

/// Import the C implementations of termios for use when linking libc.
const c = @cImport({
    @cInclude("termios.h");
    @cInclude("sys/ioctl.h");
});

/// Linux has a syscall-based Termios implementation in stdlib, but
/// has no implementation for BSDs or Darwin. Those operating systems
/// require libc anyway, so we use the libc Termios on these targets.
pub const Termios = if (std.os.builtin.tag == .linux) std.os.termios else c.termios;

/// Get the current Termios struct for the given file descriptor.
/// This variant also checks whether the fd is a tty.
pub fn tcgetattrInit(self: *PosixTty) PosixTty.InitError!Termios {
    if (std.builtin.os.tag != .linux) while (true) {
        var out: Termios = undefined;
        switch (std.os.errno(c.tcgetattr(self.tty.handle, &out))) {
            0 => return out,
            std.os.EINTR => continue,
            std.os.ENOTTY => return error.NotATerminal,
            else => |err| return std.os.unexpectedErrno(err),
        }
    };
    return std.os.tcgetattr(file.handle);
}

/// Get the current Termios struct for the given file descriptor.
/// Caller asserts that the fd is a tty.
pub fn tcgetattr(self: *PosixTty) error{Unexpected}!Termios {
    return self.tcgetattrInit() catch |err| switch (err) {
        error.NotATerminal => unreachable,
        error.Unexpected => return err,
    };
}

/// Control when termios changes are propagated.
pub const TCSA = if (std.builtin.os.tag == .linux)
    std.os.TCSA
else
    extern enum(c_uint) {
        /// Termios changes are propagated immediately.
        NOW,
        /// Termios changes are propagated after all pending output
        /// has been written to the terminal device.
        DRAIN,
        /// Termios changes are propagated after all pending output
        /// has been written to the terminal device. Additionally,
        /// any unread input will be discarded.
        FLUSH,
        _,
    };

/// Update the current Termios settings to a new set of values.
/// Caller asserts that the fd is a tty.
pub fn tcsetattr(self: *PosixTty, optional_action: TCSA, termios: Termios) error{Unexpected,ProcessOrphaned}!void {
    if (std.builtin.tag != .linux) while (true) {
        switch (std.os.errno(c.tcsetattr(self.tty.handle, @enumToInt(optional_action), &termios))) {
            0 => return,
            std.os.EINTR => continue,
            std.os.EIO => return error.ProcessOrphaned,
            std.os.ENOTTY => unreachable,
            else => |err| std.os.unexpectedErrno(err),
        }
    };
    return std.os.tcsetattr(self.tty.handle, optional_action, termios);
}
