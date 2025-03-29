const std = @import("std");

const librdkafka = @cImport({
    @cInclude("librdkafka/rdkafka.h");
});

const config = @import("config.zig");
const Message = @import("message.zig").Message;
const topic = @import("topic.zig");
const utils = @import("utils.zig");
const cb = @import("callbacks.zig");

pub const Producer = struct {
    const Self = @This();
    _producer: ?*librdkafka.rd_kafka_t,
    _topic: ?*librdkafka.struct_rd_kafka_topic_s,

    pub fn createKafkaProducer(kafka_conf: ?*librdkafka.struct_rd_kafka_conf_s) ?*librdkafka.rd_kafka_t {
        var error_message: [512]u8 = undefined;
        const kafka_producer: ?*librdkafka.rd_kafka_t = librdkafka.rd_kafka_new(librdkafka.RD_KAFKA_PRODUCER, kafka_conf, &error_message, error_message.len);
        if (kafka_producer == null) {
            @branchHint(.unlikely);
            @panic(&error_message);
        }
        std.log.info("kafka producer initialized", .{});
        return kafka_producer;
    }

    pub fn init(kafka_conf: ?*librdkafka.struct_rd_kafka_conf_s, topic_conf: ?*librdkafka.struct_rd_kafka_topic_conf_s, topic_name: [*]const u8) Self {
        const kafka_producer = createKafkaProducer(kafka_conf);
        const kafka_topic: ?*librdkafka.struct_rd_kafka_topic_s = topic.createTopic(kafka_producer, topic_conf, topic_name);
        return Self{ ._producer = kafka_producer, ._topic = kafka_topic };
    }

    pub fn deinit(self: Self) void {
        if (librdkafka.rd_kafka_flush(self._producer, 60_000) != 0) {
            @branchHint(.unlikely);
            std.log.err("failed to flush messages", .{});
        }
        librdkafka.rd_kafka_topic_destroy(self._topic);
        librdkafka.rd_kafka_destroy(self._producer);
        std.log.info("kafka producer deinitialized", .{});
    }

    pub fn send(self: Self, message: []const u8, key: []const u8) void {
        const message_ptr: ?*anyopaque = @constCast(message.ptr);
        const key_ptr: ?*anyopaque = @constCast(key.ptr);
        const err = librdkafka.rd_kafka_produce(
            self._topic,
            librdkafka.RD_KAFKA_PARTITION_UA,
            librdkafka.RD_KAFKA_MSG_F_COPY,
            message_ptr,
            message.len,
            key_ptr,
            key.len,
            null,
        );

        if (err != 0) {
            @branchHint(.unlikely);
            std.log.err("Failed to send message: {s}", .{utils.getLastError()});
        } else {
            std.log.info("Message sent successfully!", .{});
        }
    }

    // Wait for all messages to be sent.
    pub inline fn wait(self: Self, comptime timeout_ms: u16) void {
        while (librdkafka.rd_kafka_outq_len(self._producer) > 0) {
            _ = librdkafka.rd_kafka_poll(self._producer, timeout_ms);
        }
    }

    pub inline fn init_transactions(self: Self, comptime timeout_ms: u16) i32 {
        const err: ?*librdkafka.rd_kafka_error_t = librdkafka.rd_kafka_init_transactions(self._producer, timeout_ms);
        const err_code = utils.err2code(err);
        if (err_code == 0) {
            std.log.info("Transactions initialized successfully!", .{});
            return 0;
        }
        std.log.err("Failed to initialize transactions: {s}", .{utils.err2Str(err_code)});
        return err_code;
    }

    pub inline fn begin_transaction(self: Self) i32 {
        const err: ?*librdkafka.rd_kafka_error_t = librdkafka.rd_kafka_begin_transaction(self._producer);
        const err_code = utils.err2code(err);
        if (err_code == 0) {
            std.log.info("Transaction started successfully!", .{});
            return 0;
        }
        std.log.err("Failed to begin transaction: {s}", .{utils.err2Str(err_code)});
        return err_code;
    }

    pub inline fn commit_transaction(self: Self) i32 {
        const err: ?*librdkafka.rd_kafka_error_t = librdkafka.rd_kafka_commit_transaction(self._producer);
        const err_code = utils.err2code(err);
        if (err_code == 0) {
            std.log.info("Transaction comitted successfully!", .{});
            return 0;
        }
        std.log.err("Failed to commit transaction: {s}", .{utils.err2Str(err_code)});
        return err_code;
    }

    pub inline fn abort_transaction(self: Self, timeout_ms: u16) i32 {
        const err: ?*librdkafka.rd_kafka_error_t = librdkafka.rd_kafka_abort_transaction(self._producer, timeout_ms);
        const err_code = utils.err2code(err);
        if (err_code == 0) {
            std.log.info("Transaction aborted successfully!", .{});
            return 0;
        }
        std.log.err("Failed to abord transaction: {s}", utils.err2Str(err_code));
        return err_code;
    }
};

// TODO: mock it
test "test get Producer Ok" {
    var config_builder = config.Builder.get();
    const conf = config_builder
        .with("bootstrap.servers", "localhost:9092")
        .with("enable.idempotence", "true")
        .with("batch.num.messages", "10")
        .with("reconnect.backoff.ms", "1000")
        .with("reconnect.backoff.max.ms", "5000")
        .with("linger.ms", "100")
        .with("delivery.timeout.ms", "1800000")
        .with("compression.codec", "snappy")
        .with("batch.size", "16384")
        .build();

    const TestCbWrapper = struct {
        fn onMessageSent(message: Message) void {
            std.log.info("Message sent: {s}", .{message.getPayload()});
        }
    };

    cb.setCb(conf, TestCbWrapper.onMessageSent);

    const TestErrCbWrapper = struct {
        fn onError(err: i32, reason: [*c]const u8) void {
            std.log.err("error code {d}; error reason {s}", .{ err, reason });
        }
    };

    cb.setErrCb(conf, TestErrCbWrapper.onError);

    var topic_config_builder = topic.Builder.get();
    const topic_conf = topic_config_builder
        .with("request.required.acks", "all")
        .build();

    const kafka_producer = Producer.init(conf, topic_conf, "foobar-topic");
    std.debug.assert(@TypeOf(kafka_producer.init_transactions(6_000)) == i32);
    std.debug.assert(@TypeOf(kafka_producer) == Producer);
    kafka_producer.deinit();
}
