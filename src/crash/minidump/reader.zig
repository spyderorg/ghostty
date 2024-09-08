const std = @import("std");
const assert = std.debug.assert;
const Allocator = std.mem.Allocator;
const external = @import("external.zig");
const stream = @import("stream.zig");
const EncodedStream = stream.EncodedStream;

const log = std.log.scoped(.minidump_reader);

/// Possible minidump-specific errors that can occur when reading a minidump.
/// This isn't the full error set since IO errors can also occur depending
/// on the Source type.
pub const ReadError = error{
    InvalidHeader,
    InvalidVersion,
};

/// Reader creates a new minidump reader for the given source type. The
/// source must have both a "reader()" and "seekableStream()" function.
///
/// Given the format of a minidump file, we must keep the source open and
/// continually access it because the format of the minidump is full of
/// pointers and offsets that we must follow depending on the stream types.
/// Also, since we're not aware of all stream types (in fact its impossible
/// to be aware since custom stream types are allowed), its possible any stream
/// type can define their own pointers and offsets. So, the source must always
/// be available so callers can decode the streams as needed.
pub fn Reader(comptime Source: type) type {
    return struct {
        const Self = @This();

        /// The source data.
        source: Source,

        /// The endianness of the minidump file. This is detected by reading
        /// the byte order of the header.
        endian: std.builtin.Endian,

        /// The number of streams within the minidump file. This is read from
        /// the header and stored here so we can quickly access them. Note
        /// the stream types require reading the source; this is an optimization
        /// to avoid any allocations on the reader and the caller can choose
        /// to store them if they want.
        stream_count: u32,
        stream_directory_rva: u32,

        const SourceCallable = switch (@typeInfo(Source)) {
            .Pointer => |v| v.child,
            .Struct => Source,
            else => @compileError("Source type must be a pointer or struct"),
        };

        const SourceReader = @typeInfo(@TypeOf(SourceCallable.reader)).Fn.return_type.?;
        const SourceSeeker = @typeInfo(@TypeOf(SourceCallable.seekableStream)).Fn.return_type.?;

        /// The reader type for stream reading. This is a LimitedReader so
        /// you must still call reader() on the result to get the actual
        /// reader to read the data.
        pub const StreamReader = std.io.LimitedReader(SourceReader);

        /// Initialize a reader. The source must remain available for the entire
        /// lifetime of the reader. The reader does not take ownership of the
        /// source so if it has resources that need to be cleaned up, the caller
        /// must do so once the reader is no longer needed.
        pub fn init(source: Source) !Self {
            const header, const endian = try readHeader(Source, source);
            return .{
                .source = source,
                .endian = endian,
                .stream_count = header.stream_count,
                .stream_directory_rva = header.stream_directory_rva,
            };
        }

        /// Return a StreamReader for the given directory type. This streams
        /// from the underlying source so the returned reader is only valid
        /// as long as the source is unmodified (i.e. the source is not
        /// closed, the source is not seeked, etc.).
        pub fn streamReader(
            self: *const Self,
            dir: external.Directory,
        ) SourceSeeker.SeekError!StreamReader {
            try self.source.seekableStream().seekTo(dir.location.rva);
            return .{
                .inner_reader = self.source.reader(),
                .bytes_left = dir.location.data_size,
            };
        }

        /// Get the directory entry with the given index.
        ///
        /// Asserts the index is valid (idx < stream_count).
        pub fn directory(self: *const Self, idx: usize) !external.Directory {
            assert(idx < self.stream_count);

            // Seek to the directory.
            const offset: u32 = @intCast(@sizeOf(external.Directory) * idx);
            const rva: u32 = self.stream_directory_rva + offset;
            try self.source.seekableStream().seekTo(rva);

            // Read the directory.
            return try self.source.reader().readStructEndian(
                external.Directory,
                self.endian,
            );
        }
    };
}

/// Reads the header for the minidump file and returns endianness of
/// the file.
fn readHeader(comptime T: type, source: T) !struct {
    external.Header,
    std.builtin.Endian,
} {
    // Start by trying LE.
    var endian: std.builtin.Endian = .little;
    var header = try source.reader().readStructEndian(external.Header, endian);

    // If the signature doesn't match, we assume its BE.
    if (header.signature != external.signature) {
        // Seek back to the start of the file so we can reread.
        try source.seekableStream().seekTo(0);

        // Try BE, if the signature doesn't match, return an error.
        endian = .big;
        header = try source.reader().readStructEndian(external.Header, endian);
        if (header.signature != external.signature) return ReadError.InvalidHeader;
    }

    // "The low-order word is MINIDUMP_VERSION. The high-order word is an
    // internal value that is implementation specific."
    if (header.version.low != external.version) return ReadError.InvalidVersion;

    return .{ header, endian };
}

// Uncomment to dump some debug information for a minidump file.
test "Minidump debug" {
    var fbs = std.io.fixedBufferStream(@embedFile("../testdata/macos.dmp"));
    const r = try Reader(*@TypeOf(fbs)).init(&fbs);
    for (0..r.stream_count) |i| {
        const dir = try r.directory(i);
        log.warn("directory i={} dir={}", .{ i, dir });
    }
}

test "Minidump read" {
    const testing = std.testing;
    const alloc = testing.allocator;

    var fbs = std.io.fixedBufferStream(@embedFile("../testdata/macos.dmp"));
    const r = try Reader(*@TypeOf(fbs)).init(&fbs);
    try testing.expectEqual(std.builtin.Endian.little, r.endian);
    try testing.expectEqual(7, r.stream_count);
    {
        const dir = try r.directory(0);
        try testing.expectEqual(3, dir.stream_type);
        try testing.expectEqual(584, dir.location.data_size);

        var bytes = std.ArrayList(u8).init(alloc);
        defer bytes.deinit();
        var sr = try r.streamReader(dir);
        try sr.reader().readAllArrayList(&bytes, std.math.maxInt(usize));
        try testing.expectEqual(584, bytes.items.len);
    }
}
