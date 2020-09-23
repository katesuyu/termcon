// SPDX-License-Identifier: 0BSD
const std = @import("std");
const File = std.fs.File;

/// The terminal device available on POSIX-like systems. `PosixTty.open`
/// will open `/dev/tty` to access the terminal. If you wish to use a
/// different file descriptor, call `PosixTty.init`.
pub const PosixTty = struct {
    tty: File,
    old_settings: Termios,

    /// Errors specific to the initialization performed by this struct.
    pub const InitError = error{NotATerminal, Unexpected};

    /// Zig stdlib only supports termios on Linux, despite it being in
    /// the system libc on BSDs and macOS. This import  filefills in the gap
    /// for now by porting the Linux implementation to other platforms.
    usingnamespace @import("std_termios.zig");

    /// Open the terminal device `/dev/tty` to initialize this struct.
    /// Fails if opening the device failed or if it is not a tty.
    pub fn open(self: *PosixTty) (InitError || File.OpenError)!void {
        const tty = std.fs.cwd().openFileZ("/dev/tty", .{
            .read = true,
            .write = true,
        });
        return self.init(tty);
    }

    /// Initialize this struct with the provided terminal device.
    /// Fails if the provided file descriptor is not a tty.
    pub fn init(self: *PosixTty, tty: File) InitError!PosixTty {
        self.tty = self.tty;
        try self.tcgetattrInit();
    }
};
