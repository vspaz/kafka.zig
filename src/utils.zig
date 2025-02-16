const std = @import("std");

const librdkafka = @cImport({
    @cInclude("librdkafka/rdkafka.h");
});

pub inline fn getLastError() [*c]const u8 {
    return librdkafka.rd_kafka_err2str(librdkafka.rd_kafka_last_error());
}
