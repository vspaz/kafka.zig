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
        return []const u8{};
    }
};
