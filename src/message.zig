const std = @import("std");
const librdkafka = @cImport({
    @cInclude("librdkafka/rdkafka.h");
});

// https://docs.confluent.io/platform/current/clients/librdkafka/html/classRdKafka_1_1Message.html
pub const Message = struct {
    const Self = @This();
    _message: *librdkafka.rd_kafka_message_t,

    pub fn getPayload(self: Self) []const u8 {
        if (self._message.payload) |payload| {
            const payload_len = self.getPayloadLen();
            if (payload_len > 0) {
                return @as([*]u8, @ptrCast(payload))[0..payload_len];
            }
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
        if (self._message.key) |key| {
            const key_len = self.getKeyLen();
            if (key_len > 0) {
                return @as([*]u8, @ptrCast(key))[0..key_len];
            }
        }
        return &[_]u8{};
    }

    pub fn getKeyLen(self: Self) usize {
        return self._message.key_len;
    }

    pub fn getOffset(self: Self) i64 {
        return self._message.offset;
    }

    pub fn getErrCode(self: Self) i32 {
        return @as(i32, self._message.err);
    }

    pub fn getTimestamp(self: Self) i64 {
        var set_by: c_uint = undefined; // 0 -> no timestamp is available; 1 -> set by producer; 2 -> set by kafka broker
        return librdkafka.rd_kafka_message_timestamp(self._message, &set_by);
    }
};
