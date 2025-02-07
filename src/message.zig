const std = @import("std");
const librdkafka = @cImport({
    @cInclude("librdkafka/rdkafka.h");
});

pub const Message = struct {
    const Self = @This();
    _message: *librdkafka.rd_kafka_message_t,

    pub fn getPayload(self: Self) []const u8 {
        if (self._message.payload != null and self._message.len > 0) {
            return @as([*]u8, @ptrCast(self._message.payload))[0..self._message.len];
        }
        return &[_]u8{};
    }

    pub fn getPartition(self: Self) i32 {
        return self._message.partition;
    }

    pub fn getPayloadLen(self: Self) usize {
        return self._message.len;
    }

    pub fn getKey(self: Self) []const u8 {
        if (self._message.key != null and self._message.key.len > 0) {
            return @as([*]u8, @ptrCast(self._message.key))[0..self._message.key];
        }
        return &[_]u8{};
    }

    pub fn getKeyLen(self: Self) usize {
        return self._message.key.len;
    }

    pub fn getOffset(self: Self) i64 {
        return self._message.offset;
    }

    pub fn getErrCode(self: Self) i32 {
        return @as(i32, self._message.err);
    }
};
