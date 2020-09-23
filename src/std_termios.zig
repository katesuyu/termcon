// SPDX-License-Identifier: MIT
// Copyright (c) 2015-2020 Zig Contributors
// This file is part of [zig](https://ziglang.org/), which is MIT licensed.
// The MIT license requires this copyright notice to be included in all copies
// and substantial portions of the software.
const std = @import("std");
const PosixTty = @import("termcon.zig").device.PosixTty;

/// Import the C implementations of termios for use when linking libc.
const c = @cImport({
    @cInclude("termios.h");
    @cInclude("sys/ioctl.h");
});

/// Use libc termios where possible because BSD and Darwin targets do not
/// have a stable syscall interface. On Linux, `std.os` has a syscall-based
/// Termios implementation that we use instead.
pub const Termios = if (std.builtin.link_libc) c.termios else std.os.termios;

/// Get the current Termios struct for the given file descriptor.
/// This variant also checks whether the fd is a tty.
pub fn tcgetattrInit(self: *PosixTty) PosixTty.InitError!void {
    if (std.builtin.link_libc) while (true) {
        const errno = std.os.errno(c.tcgetattr(self.tty.handle, &self.old_settings));
        switch (errno) {
            0 => return,
            std.os.EINTR => continue,
            std.os.ENOTTY => return error.NotATerminal,
            else => return std.os.unexpectedErrno(errno),
        }
    };
    self.old_settings = try std.os.tcgetattr(file.handle);
}

/// Get the current Termios struct for the given file descriptor.
/// Caller asserts that the fd is a tty.
pub fn tcgetattr(self: *PosixTty) error{Unexpected}!void {
    self.tcgetattrInit() catch |err| switch (err) {
        error.NotATerminal => unreachable,
        error.Unexpected => return err,
    };
}
