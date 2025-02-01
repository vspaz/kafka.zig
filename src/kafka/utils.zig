const std = @import("std");
const librdkafka = @cImport({
    @cInclude("librdkafka/rdkafka.h");
});

pub fn getLastError() [*c]const u8 {
    return librdkafka.rd_kafka_err2str(librdkafka.rd_kafka_last_error());
}

pub fn toSlice(message: *librdkafka.rd_kafka_message_t) []const u8 {
    return @as([*]u8, @ptrCast(message.payload))[0..message.len];
}
