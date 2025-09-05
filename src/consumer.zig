const std = @import("std");

const librdkafka = @import("cimport.zig").librdkafka;

const config = @import("config.zig");
const Message = @import("message.zig").Message;
const errors = @import("errors.zig");

pub const Consumer = struct {
    const Self = @This();
    _consumer: ?*librdkafka.rd_kafka_t,
    _topics: ?*librdkafka.struct_rd_kafka_topic_partition_list_s = undefined,
    _message_count: std.atomic.Value(u32) = std.atomic.Value(u32).init(0),

    fn createKafkaConsumer(kafka_conf: ?*librdkafka.struct_rd_kafka_conf_s) ?*librdkafka.rd_kafka_t {
        var error_message: [512]u8 = undefined;
        const kafka_consumer: ?*librdkafka.rd_kafka_t = librdkafka.rd_kafka_new(librdkafka.RD_KAFKA_CONSUMER, kafka_conf, &error_message, error_message.len);
        if (kafka_consumer == null) {
            @branchHint(.unlikely);
            @panic(&error_message);
        }
        std.log.info("kafka consumer initialized", .{});
        return kafka_consumer;
    }

    pub inline fn init(kafka_conf: ?*librdkafka.struct_rd_kafka_conf_s) Self {
        return Self{ ._consumer = createKafkaConsumer(kafka_conf) };
    }

    pub inline fn deinit(self: Self) void {
        librdkafka.rd_kafka_topic_partition_list_destroy(self._topics);
        librdkafka.rd_kafka_destroy(self._consumer);
        std.log.info("kafka consumer deinitialized", .{});
    }

    pub fn subscribe(self: *Self, topic_names: []const []const u8) void {
        self._topics = librdkafka.rd_kafka_topic_partition_list_new(@intCast(topic_names.len));
        if (self._topics == null) {
            @branchHint(.unlikely);
            @panic("failed to create topic list");
        }
        for (topic_names) |topic_name| {
            _ = librdkafka.rd_kafka_topic_partition_list_add(self._topics, topic_name.ptr, librdkafka.RD_KAFKA_PARTITION_UA);
        }
        const err_code: c_int = librdkafka.rd_kafka_subscribe(self._consumer, self._topics);
        if (err_code != librdkafka.RD_KAFKA_RESP_ERR_NO_ERROR) {
            @branchHint(.unlikely);
            std.log.err("failed to subscribe {s}", .{errors.err2Str(err_code)});
            @panic("failed to subscribe");
        }

        std.log.info("kafka consumer subscribed", .{});
    }

    pub fn consume_start(self: Self, topic: ?*librdkafka.struct_rd_kafka_topic_s, partition: i32, offset: i64) void {
        if (librdkafka.rd_kafka_consume_start(topic, partition, offset) == librdkafka.RD_KAFKA_RESP_ERR_UNKNOWN) {
            @branchHint(.unlikely);
            std.log.err("failed to start consumer {s}", .{errors.getLastError()});
            librdkafka.rd_kafka_topic_destroy(topic);
            librdkafka.rd_kafka_destroy(self._consumer);
            @panic("failed to start consumer {s}");
        }
    }

    pub inline fn consume_stop(topic: ?*librdkafka.struct_rd_kafka_topic_s, partition: i32) void {
        if (librdkafka.rd_kafka_consume_stop(topic, partition) == librdkafka.RD_KAFKA_RESP_ERR_UNKNOWN) {
            @branchHint(.unlikely);
            std.log.err("failed to stop consumer {s}", .{errors.getLastError()});
        } else {
            std.log.info("kafka consumer stopped", .{});
        }
        librdkafka.rd_kafka_topic_destroy(topic);
    }

    pub inline fn consume(self: Self, topic: ?*librdkafka.struct_rd_kafka_topic_s, partition: i32, comptime timeout_ms: u16) ?Message {
        _ = self._message_count.fetchAdd(1, std.builtin.AtomicOrder.seq_cst);
        const message_or_null = librdkafka.rd_kafka_consume(topic, partition, timeout_ms);
        if (message_or_null) |message| {
            return Message.init(message);
        }
        return null;
    }

    pub fn poll(self: *Self, comptime timeout_ms: u16) ?Message {
        _ = self._message_count.fetchAdd(1, std.builtin.AtomicOrder.seq_cst);
        const message_or_null = librdkafka.rd_kafka_consumer_poll(self._consumer, timeout_ms);
        if (message_or_null) |message| {
            return Message.init(message);
        }
        return null;
    }

    pub fn commitOffset(self: Self, message: Message) void {
        const err_code: c_int = librdkafka.rd_kafka_commit_message(self._consumer, message._message, 1);
        if (err_code != librdkafka.RD_KAFKA_RESP_ERR_NO_ERROR) {
            @branchHint(.unlikely);
            std.log.err("failed to commit offset {s}", .{errors.err2Str(err_code)});
            return;
        }
        std.log.info("Offset {d} commited", .{message.getOffset()});
    }

    pub fn commitOffsetOnEvery(self: Self, comptime count: u32, message: Message) void {
        if (self._message_count.load(std.builtin.AtomicOrder.seq_cst) % count == 0) {
            const offset: c_int = @intCast(message.getOffset());
            if (librdkafka.rd_kafka_commit_message(self._consumer, message._message, offset) != librdkafka.RD_KAFKA_RESP_ERR_NO_ERROR) {
                @branchHint(.unlikely);
                std.log.err("failed to commit offset {s}", .{errors.getLastError()});
            }
            std.log.info("Offset {d} commited", .{offset});
        }
    }

    pub inline fn unsubscribe(self: Self) void {
        if (librdkafka.rd_kafka_unsubscribe(self._consumer) != librdkafka.RD_KAFKA_RESP_ERR_NO_ERROR) {
            std.log.err("failed to commit offset {s}", .{errors.getLastError()});
            return;
        }
        std.log.info("consumer unsubscribed successfully.", .{});
    }

    pub inline fn close(self: Self) void {
        if (librdkafka.rd_kafka_consumer_close(self._consumer) != librdkafka.RD_KAFKA_RESP_ERR_NO_ERROR) {
            @branchHint(.unlikely);
            std.log.err("Failed to close consumer: {s}", .{errors.getLastError()});
            return;
        }
        std.log.info("Consumer closed successfully.", .{});
    }
};

// TODO: mock it
test "test consumer init ok" {
    var consumer_config_builder = config.Builder.get();
    const consumer_conf = consumer_config_builder
        .with("bootstrap.servers", "localhost:9092")
        .with("group.id", "consumer1")
        .with("auto.offset.reset", "earliest")
        .with("enable.auto.commit", "false")
        .with("reconnect.backoff.ms", "100")
        .with("reconnect.backoff.max.ms", "1000")
        .build();
    var kafka_consumer = Consumer.init(consumer_conf);
    defer kafka_consumer.deinit();
    const topics = [_][]const u8{"topic-name2"};
    kafka_consumer.subscribe(&topics);
    const message_or_null = kafka_consumer.poll(100);
    if (message_or_null) |message| {
        std.log.info("key {s}", .{message.getKey()});
        _ = message.getPayload();
        kafka_consumer.commitOffset(message);
    }
    kafka_consumer.unsubscribe();
    kafka_consumer.close();
}
