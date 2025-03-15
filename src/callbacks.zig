const librdkafka = @cImport({
    @cInclude("librdkafka/rdkafka.h");
});

const Message = @import("message.zig").Message;

pub fn setConsumeCb(conf: ?*librdkafka.struct_rd_kafka_conf_s, comptime cb: fn (message: Message) void) void {
    const cbAdapter = struct {
        fn callback(rkmessage: [*c]const librdkafka.rd_kafka_message_t, _: ?*anyopaque) callconv(.C) void {
            var message = rkmessage.*;
            cb(.{ ._message = &message });
        }
    };
    librdkafka.rd_kafka_conf_set_consume_cb(conf, cbAdapter.callback);
}

pub fn setCb(conf: ?*librdkafka.struct_rd_kafka_conf_s, comptime cb: fn (message: Message) void) void {
    const cbAdapter = struct {
        fn callback(_: ?*librdkafka.rd_kafka_t, rkmessage: [*c]const librdkafka.rd_kafka_message_t, _: ?*anyopaque) callconv(.C) void {
            var message = rkmessage.*;
            cb(.{ ._message = &message });
        }
    };
    librdkafka.rd_kafka_conf_set_dr_msg_cb(conf, cbAdapter.callback);
}

pub fn setErrCb(conf: ?*librdkafka.struct_rd_kafka_conf_s, comptime cb: fn (err: i32, reason: [*c]const u8) void) void {
    const errCbAdapter = struct {
        fn callback(_: ?*librdkafka.rd_kafka_t, err: c_int, reason: [*c]const u8, _: ?*anyopaque) callconv(.C) void {
            cb(err, reason);
        }
    };
    librdkafka.rd_kafka_conf_set_error_cb(conf, errCbAdapter.callback);
}
