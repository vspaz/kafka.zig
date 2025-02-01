const std = @import("std");
const librdkafka = @cImport({
    @cInclude("librdkafka/rdkafka.h");
});

pub fn free(message: ?*librdkafka.rd_kafka_message_t) void {
    librdkafka.rd_kafka_message_destroy(message);
}

fn getLastError() [*c]const u8 {
    return librdkafka.rd_kafka_err2str(librdkafka.rd_kafka_last_error());
}

pub fn decodePayload(message: *librdkafka.rd_kafka_message_t) []const u8 {
    return @as([*]u8, @ptrCast(message.payload))[0..message.len];
}

pub const Consumer = struct {
    const Self = @This();
    _consumer: ?*librdkafka.rd_kafka_t,
    _msg_count: u32 = 0,

    fn createKafkaConsumer(conf: ?*librdkafka.struct_rd_kafka_conf_s) ?*librdkafka.rd_kafka_t {
        var error_message: [512]u8 = undefined;
        const kafka_consumer: ?*librdkafka.rd_kafka_t = librdkafka.rd_kafka_new(librdkafka.RD_KAFKA_CONSUMER, conf, &error_message, error_message.len);
        if (kafka_consumer == null) {
            @panic(&error_message);
        }
        std.log.info("kafka consumer initialized", .{});
        return kafka_consumer;
    }

    pub fn init(conf: ?*librdkafka.struct_rd_kafka_conf_s) Consumer {
        return .{ ._consumer = createKafkaConsumer(conf) };
    }

    pub fn deinit(self: Consumer) void {
        librdkafka.rd_kafka_destroy(self._consumer);
        std.log.info("kafka consumer deinitialized", .{});
    }

    pub fn subscribe(self: Consumer, topic_names: []const []const u8) void {
        const topics = librdkafka.rd_kafka_topic_partition_list_new(@intCast(topic_names.len));
        if (topics == null) {
            @panic("failed to create topic list");
        }
        defer librdkafka.rd_kafka_topic_partition_list_destroy(topics);
        for (topic_names) |topic| {
            _ = librdkafka.rd_kafka_topic_partition_list_add(topics, topic.ptr, librdkafka.RD_KAFKA_PARTITION_UA);
        }
        if (librdkafka.rd_kafka_subscribe(self._consumer, topics) != librdkafka.RD_KAFKA_RESP_ERR_NO_ERROR) {
            std.log.err("failed to subscribe {s}", .{getLastError()});
            @panic("failed to subscribe {s}");
        }

        std.log.info("kafka consumer subscribed", .{});
    }

    pub fn poll(self: *Consumer, timeout: c_int) ?*librdkafka.rd_kafka_message_t {
        self._msg_count += 1;
        return librdkafka.rd_kafka_consumer_poll(self._consumer, timeout);
    }

    pub fn commitOffset(self: Consumer, message: *librdkafka.rd_kafka_message_t) void {
        const err = librdkafka.rd_kafka_commit_message(self._consumer, message, 1);
        if (err != librdkafka.RD_KAFKA_RESP_ERR_NO_ERROR) {
            std.log.err("failed to commit offset {s}", .{getLastError()});
            return;
        }
        std.log.info("Offset {d} commited", .{message.offset});
    }

    pub fn commitOffsetOnEvery(self: Consumer, count: u32, message: *librdkafka.rd_kafka_message_t) void {
        if (self._msg_count % count == 0) {
            if (librdkafka.rd_kafka_commit_message(self._consumer, message, message.offset) != librdkafka.RD_KAFKA_RESP_ERR_NO_ERROR) {
                std.log.err("failed to commit offset {s}", .{getLastError()});
            }
            std.log.info("Offset {d} commited", .{message.offset});
        }
    }

    pub fn unsubscribe(self: Consumer) void {
        if (librdkafka.rd_kafka_unsubscribe(self._consumer) != librdkafka.RD_KAFKA_RESP_ERR_NO_ERROR) {
            std.log.err("failed to commit offset {s}", .{getLastError()});
            return;
        }
        std.log.info("consumer unsubscribed successfully.", .{});
    }

    pub fn close(self: Consumer) void {
        if (librdkafka.rd_kafka_consumer_close(self._consumer) != librdkafka.RD_KAFKA_RESP_ERR_NO_ERROR) {
            std.log.err("Failed to close consumer: {s}", .{getLastError()});
            return;
        }
        std.log.info("Consumer closed successfully.", .{});
    }
};
