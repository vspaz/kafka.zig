const std = @import("std");

const librdkafka = @import("cimport.zig").librdkafka;
const Message = @import("message.zig").Message;

pub fn setConsumeCb(conf: ?*librdkafka.struct_rd_kafka_conf_s, cb: *const fn (message: Message) void) !void {
    if (conf == null) {
        return error.NullConf;
    }

    const allocator = std.heap.c_allocator;
    const ctx = try allocator.create(cbCtx);
    ctx.cb = cb;

    librdkafka.rd_kafka_conf_set_dr_msg_cb(conf, cbAdapter);
    librdkafka.rd_kafka_conf_set_opaque(conf, ctx);
}

const cbCtx = struct {
    cb: *const fn (message: Message) void,
};

fn cbAdapter(_: ?*librdkafka.rd_kafka_t, rkmessage: [*c]const librdkafka.rd_kafka_message_t, opaq: ?*anyopaque) callconv(.c) void {
    if (opaq) |ptr| {
        const ctx: *cbCtx = @ptrCast(@alignCast(ptr));
        var message = rkmessage.*;
        ctx.cb(.{ ._message = &message });
    }
}

pub fn setCb(conf: ?*librdkafka.struct_rd_kafka_conf_s, cb: *const fn (message: Message) void) !void {
    if (conf == null) {
        return error.NullConf;
    }

    const allocator = std.heap.c_allocator;
    const ctx = try allocator.create(cbCtx);
    ctx.cb = cb;

    librdkafka.rd_kafka_conf_set_dr_msg_cb(conf, cbAdapter);
    librdkafka.rd_kafka_conf_set_opaque(conf, ctx);
}

const errCbCtx = struct {
    cb: *const fn (err: i32, reason: [*c]const u8) void,
};

fn errCbAdapter(_: ?*librdkafka.rd_kafka_t, err: c_int, reason: [*c]const u8, opaq: ?*anyopaque) callconv(.c) void {
    if (opaq) |ptr| {
        const ctx: *errCbCtx = @ptrCast(@alignCast(ptr));
        ctx.cb(err, reason);
    }
}

pub fn setErrCb(conf: ?*librdkafka.struct_rd_kafka_conf_s, cb: *const fn (err: i32, reason: [*c]const u8) void) !void {
    if (conf == null) {
        return error.NullConf;
    }
    const allocator = std.heap.c_allocator;
    const ctx = try allocator.create(errCbCtx);
    ctx.cb = cb;

    librdkafka.rd_kafka_conf_set_error_cb(conf, errCbAdapter);
    librdkafka.rd_kafka_conf_set_opaque(conf, ctx);
}
