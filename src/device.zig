// SPDX-License-Identifier: 0BSD
const std = @import("std");
const File = std.fs.File;

const c = @cImport({
    @cInclude("termios.h");
    @cInclude("sys/ioctl.h");
});

/// The terminal device available on POSIX-like systems. `PosixTty.open`
/// will open `/dev/tty` to access the terminal. If you wish to use a
/// different file descriptor, call `PosixTty.init`.
pub const PosixTty = struct {
    tty: File,
    old_settings: Termios,

    /// The options to be set upon opening the terminal device.
    pub const Options = struct {
        raw_mode: bool = true,
        alt_screen: bool = false,
    };

    /// Errors specific to the initialization performed by this struct.
    pub const InitError = error{NotATerminal, Unexpected};

    /// Open the terminal device `/dev/tty` to initialize this struct.
    /// Fails if opening the device failed or if it is not a tty.
    pub fn open(options: Options) (InitError || File.OpenError)!PosixTty {
        const tty = options.tty orelse try std.fs.cwd().openFileZ("/dev/tty", .{
            .read = true,
            .write = true,
        });
        return PosixTty.init(tty, options);
    }

    /// Initialize this struct with the provided terminal device.
    /// Fails if the provided file descriptor is not a tty.
    pub fn init(tty: File, options: Options) InitError!PosixTty {
        var self = PosixTty{
            .tty = tty,
            .old_settings = undefined,
        };
        try tcgetattrInit(tty, self.old_settings);
        return self;
    }

    /// Use libc termios where possible because BSD and Darwin targets do not
    /// have a stable syscall interface. On Linux, `std.os` has a syscall-based
    /// Termios implementation that we use instead.
    const Termios = if (std.builtin.link_libc) c.termios else std.os.termios;
    /// Get the current Termios struct for the given file descriptor.
    /// This variant also checks whether the fd is a tty.
    fn tcgetattrInit(file: File, out: *Termios) InitError!void {
        if (std.builtin.link_libc) while (true) {
            const errno = std.os.errno(c.tcgetattr(file.handle, out));
            switch (errno) {
                0 => return,
                std.os.EINTR => continue,
                std.os.ENOTTY => return error.NotATerminal,
                else => return std.os.unexpectedErrno(errno),
            }
        };
        out.* = try std.os.tcgetattr(file.handle);
    }
    /// Get the current Termios struct for the given file descriptor.
    /// Caller asserts that the fd is a tty.
    fn tcgetattr(file: File, out: *Termios) std.os.UnexpectedError!void {
        tcgetattrInit(file, out) catch |err| switch (err) {
            error.NotATerminal => unreachable,
            error.Unexpected => return err,
        };
    }
};
