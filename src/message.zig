const std = @import("std");

const librdkafka = @import("cimport.zig").librdkafka;

// https://docs.confluent.io/platform/current/clients/librdkafka/html/classRdKafka_1_1Message.html
pub const Message = struct {
    const Self = @This();
    _message: *librdkafka.rd_kafka_message_t,

    pub inline fn init(message: *librdkafka.rd_kafka_message_t) Self {
        return .{ ._message = message };
    }

    pub inline fn deinit(self: Self) void {
        librdkafka.rd_kafka_message_destroy(self._message);
    }

    pub fn getPayload(self: Self) []const u8 {
        if (self._message.payload) |payload| {
            const payload_len = self.getPayloadLen();
            if (payload_len > 0) {
                return @as([*]u8, @ptrCast(payload))[0..payload_len];
            }
        }
        return &[_]u8{};
    }

    pub inline fn getPartition(self: Self) i32 {
        return self._message.partition;
    }

    pub inline fn getPayloadLen(self: Self) usize {
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

    pub inline fn getKeyLen(self: Self) usize {
        return self._message.key_len;
    }

    pub inline fn getOffset(self: Self) i64 {
        return self._message.offset;
    }

    pub inline fn getErrCode(self: Self) i32 {
        return @as(i32, self._message.err);
    }

    pub inline fn getTimestamp(self: Self) i64 {
        var set_by: c_uint = undefined; // 0 -> no timestamp is available; 1 -> set by producer; 2 -> set by kafka broker
        return librdkafka.rd_kafka_message_timestamp(self._message, &set_by);
    }
};
