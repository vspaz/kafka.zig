const std = @import("std");

const librdkafka = @import("cimport.zig").librdkafka;

pub inline fn getLastError() [*c]const u8 {
    return librdkafka.rd_kafka_err2str(librdkafka.rd_kafka_last_error());
}

// https://docs.confluent.io/platform/current/clients/librdkafka/html/structrd__kafka__err__desc.html
pub inline fn err2Str(err_code: c_int) [*c]const u8 {
    return librdkafka.rd_kafka_err2str(err_code);
}

// https://docs.confluent.io/platform/current/clients/librdkafka/html/rdkafka_8h_source.html
pub inline fn err2code(err: ?*librdkafka.rd_kafka_error_t) i32 {
    return librdkafka.rd_kafka_error_code(err);
}

pub inline fn deinitErr(err: ?*librdkafka.rd_kafka_error_t) void {
    librdkafka.rd_kafka_error_destroy(err);
}
