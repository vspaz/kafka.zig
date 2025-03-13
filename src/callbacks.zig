const librdkafka = @cImport({
    @cInclude("librdkafka/rdkafka.h");
});

pub fn setConsumeCb(conf: ?*librdkafka.struct_rd_kafka_conf_s, comptime cb: fn (message: Message) void) void {
    const cbAdapter = struct {
        fn callback(_: ?*librdkafka.rd_kafka_t, rkmessage: [*c]const librdkafka.rd_kafka_message_t, _: ?*anyopaque) callconv(.C) void {
            var message = rkmessage.*;
            cb(.{ ._message = &message });
        }
    };
    librdkafka.rd_kafka_conf_set_consume_cb(conf, cbAdapter.callback);
}
