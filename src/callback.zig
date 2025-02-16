const librdkafka = @cImport({
    @cInclude("librdkafka/rdkafka.h");
});

const kafka = @import("kafka.zig");

pub fn setCallback(conf: ?*librdkafka.struct_rd_kafka_conf_s, cb: fn (message: kafka.Message) void) void {
    const cABIWrapper = struct {
        pub fn callback(rk: ?*librdkafka.rd_kafka_t, rkmessage: [*c]const librdkafka.rd_kafka_message_t, _: ?*anyopaque) callconv(.C) void {
            _ = rk;
            var message = rkmessage.*;
            cb(.{ ._message = &message });
        }
    };
    librdkafka.rd_kafka_conf_set_dr_msg_cb(conf, cABIWrapper.callback);
}
