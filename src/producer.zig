const librdkafka = @cImport({
    @cInclude("librdkafka/rdkafka.h");
});
const std = @import("std");
const kafka = @import("kafka.zig");
const topic = @import("topic.zig");
const utils = @import("utils.zig");

pub const Producer = struct {
    const Self = @This();
    _producer: ?*librdkafka.rd_kafka_t,
    _topic: ?*librdkafka.struct_rd_kafka_topic_s,

    fn createKafkaProducer(kafka_conf: ?*librdkafka.struct_rd_kafka_conf_s) ?*librdkafka.rd_kafka_t {
        var error_message: [512]u8 = undefined;
        const kafka_producer: ?*librdkafka.rd_kafka_t = librdkafka.rd_kafka_new(librdkafka.RD_KAFKA_PRODUCER, kafka_conf, &error_message, error_message.len);
        if (kafka_producer == null) {
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
        if (librdkafka.rd_kafka_flush(self._producer, 10_000) != 0) {
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
            std.log.err("Failed to send message: {s}", .{utils.getLastError()});
        } else {
            std.log.info("Message sent successfully!", .{});
        }
    }

    // Wait for all messages to be sent.
    pub fn wait(self: Self, interval: u16) void {
        while (librdkafka.rd_kafka_outq_len(self._producer) > 0) {
            _ = librdkafka.rd_kafka_poll(self._producer, interval);
        }
    }
};

// TODO: mock it
test "test get Producer Ok" {
    var ConfigBuilder = kafka.ConfigBuilder.get();
    const conf = ConfigBuilder
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
        fn onMessageSent(message: kafka.Message) void {
            std.log.info("Message sent: {s}", .{message.getPayload()});
        }
    };

    kafka.setCb(conf, TestCbWrapper.onMessageSent);

    var topic_config_builder = kafka.TopicBuilder.get();
    const topic_conf = topic_config_builder
        .with("request.required.acks", "all")
        .build();

    const kafka_producer = Producer.init(conf, topic_conf, "foobar-topic");
    std.debug.assert(@TypeOf(kafka_producer) == Producer);
    kafka_producer.deinit();
}
