const std = @import("std");
const librdkafka = @cImport({
    @cInclude("librdkafka/rdkafka.h");
});
const utils = @import("utils.zig");
const config = @import("config.zig");

pub const Consumer = struct {
    const Self = @This();
    _consumer: ?*librdkafka.rd_kafka_t,
    _msg_count: u32 = 0,

    fn createKafkaConsumer(kafka_conf: ?*librdkafka.struct_rd_kafka_conf_s) ?*librdkafka.rd_kafka_t {
        var error_message: [512]u8 = undefined;
        const kafka_consumer: ?*librdkafka.rd_kafka_t = librdkafka.rd_kafka_new(librdkafka.RD_KAFKA_CONSUMER, kafka_conf, &error_message, error_message.len);
        if (kafka_consumer == null) {
            @panic(&error_message);
        }
        std.log.info("kafka consumer initialized", .{});
        return kafka_consumer;
    }

    pub fn init(kafka_conf: ?*librdkafka.struct_rd_kafka_conf_s) Consumer {
        return .{ ._consumer = createKafkaConsumer(kafka_conf) };
    }

    pub fn deinit(self: Consumer) void {
        self.unsubscribe();
        self.close();
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
            std.log.err("failed to subscribe {s}", .{utils.getLastError()});
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
            std.log.err("failed to commit offset {s}", .{utils.getLastError()});
            return;
        }
        std.log.info("Offset {d} commited", .{message.offset});
    }

    pub fn commitOffsetOnEvery(self: Consumer, count: u32, message: *librdkafka.rd_kafka_message_t) void {
        if (self._msg_count % count == 0) {
            const offset: c_int = @intCast(message.offset);
            if (librdkafka.rd_kafka_commit_message(self._consumer, message, offset) != librdkafka.RD_KAFKA_RESP_ERR_NO_ERROR) {
                std.log.err("failed to commit offset {s}", .{utils.getLastError()});
            }
            std.log.info("Offset {d} commited", .{offset});
        }
    }

    pub fn unsubscribe(self: Consumer) void {
        if (librdkafka.rd_kafka_unsubscribe(self._consumer) != librdkafka.RD_KAFKA_RESP_ERR_NO_ERROR) {
            std.log.err("failed to commit offset {s}", .{utils.getLastError()});
            return;
        }
        std.log.info("consumer unsubscribed successfully.", .{});
    }

    pub fn close(self: Consumer) void {
        if (librdkafka.rd_kafka_consumer_close(self._consumer) != librdkafka.RD_KAFKA_RESP_ERR_NO_ERROR) {
            std.log.err("Failed to close consumer: {s}", .{utils.getLastError()});
            return;
        }
        std.log.info("Consumer closed successfully.", .{});
    }
};

test "test consumer init ok" {
    var consumer_config_builder = config.Builder.get();
    const consumer_conf = consumer_config_builder
        .with("bootstrap.servers", "localhost:9092")
        .with("group.id", "consumer1")
        .with("auto.offset.reset", "earliest")
        .with("auto.commit.interval.ms", "5000")
        .build();
    var kafka_consumer = Consumer.init(consumer_conf);
    const topics = [_][]const u8{"topic-name2"};
    kafka_consumer.subscribe(&topics);
}
