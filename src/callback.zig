const librdkafka = @cImport({
    @cInclude("librdkafka/rdkafka.h");
});

const Message = @import("message.zig").Message;

pub fn set(conf: ?*librdkafka.struct_rd_kafka_conf_s, comptime cb: fn (message: Message) void) void {
    const cbAdapter = struct {
        fn callback(rk: ?*librdkafka.rd_kafka_t, rkmessage: [*c]const librdkafka.rd_kafka_message_t, _: ?*anyopaque) callconv(.C) void {
            _ = rk;
            var message = rkmessage.*;
            cb(.{ ._message = &message });
        }
    };
    librdkafka.rd_kafka_conf_set_dr_msg_cb(conf, cbAdapter.callback);
}
