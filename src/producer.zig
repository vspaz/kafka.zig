const std = @import("std");

const librdkafka = @cImport({
    @cInclude("librdkafka/rdkafka.h");
});

const config = @import("config.zig");
const Message = @import("message.zig").Message;
const Metadata = @import("metadata.zig").Metadata;
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
        if (librdkafka.rd_kafka_flush(self._producer, 60_000) != 0) {
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
    pub fn wait(self: Self, comptime interval: u16) void {
        while (librdkafka.rd_kafka_outq_len(self._producer) > 0) {
            _ = librdkafka.rd_kafka_poll(self._producer, interval);
        }
    }

    pub fn getMetadata(self: Self) Metadata {
        var metadata: [*c]const librdkafka.struct_rd_kafka_metadata = undefined;
        if (librdkafka.rd_kafka_metadata(self._producer, 0, self._topic, &metadata, 5000) != librdkafka.RD_KAFKA_RESP_ERR_NO_ERROR) {
            std.log.err("Failed to fetch metadata: {s}", .{utils.getLastError()});
        }
        return .{ ._metadata = metadata };
    }
};

pub fn setCb(conf: ?*librdkafka.struct_rd_kafka_conf_s, comptime cb: fn (message: Message) void) void {
    const cbAdapter = struct {
        fn callback(rk: ?*librdkafka.rd_kafka_t, rkmessage: [*c]const librdkafka.rd_kafka_message_t, _: ?*anyopaque) callconv(.C) void {
            _ = rk;
            var message = rkmessage.*;
            cb(.{ ._message = &message });
        }
    };
    librdkafka.rd_kafka_conf_set_dr_msg_cb(conf, cbAdapter.callback);
}

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

    setCb(conf, TestCbWrapper.onMessageSent);

    var topic_config_builder = topic.Builder.get();
    const topic_conf = topic_config_builder
        .with("request.required.acks", "all")
        .build();

    const kafka_producer = Producer.init(conf, topic_conf, "foobar-topic");
    const meta = kafka_producer.getMetadata();
    std.log.info("broker count: {d}", .{meta.getBrokerCount()});
    _ = meta.getBrokers();
    meta.deinit();
    std.debug.assert(@TypeOf(kafka_producer) == Producer);
    kafka_producer.deinit();
}
