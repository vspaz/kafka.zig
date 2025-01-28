const librdkafka = @cImport({
    @cInclude("librdkafka/rdkafka.h");
});
const std = @import("std");
const config = @import("config.zig");
const assert = std.debug.assert;

pub const Producer = struct {
    _producer: ?*librdkafka.rd_kafka_t,
    _topic: ?*librdkafka.rd_kafka_topic_t = undefined,

    pub fn init(conf: ?*librdkafka.struct_rd_kafka_conf_s, topic: [*]const u8) ?Producer {
        const kafka_producer: ?*librdkafka.rd_kafka_t = librdkafka.rd_kafka_new(librdkafka.RD_KAFKA_PRODUCER, conf, null, 0);
        if (kafka_producer == null) {
            std.log.err("Failed to create Kafka producer", .{});
            return null;
        }
        std.log.info("kafka producer initialized", .{});

        const topic_conf = librdkafka.rd_kafka_topic_conf_new();
        if (topic_conf == null) {
            std.log.err("Failed to create topic configuration", .{});
            return null;
        }
        const kafka_topic = librdkafka.rd_kafka_topic_new(kafka_producer, topic, topic_conf);
        if (kafka_topic == null) {
            std.log.err("Failed to create Kafka topic", .{});
            return null;
        }
        return .{ ._producer = kafka_producer, ._topic = kafka_topic };
    }
    pub fn deinit(self: Producer) void {
        librdkafka.rd_kafka_destroy(self._producer);
    }
};

test "test get Producer Ok" {
    var ConfigBuilder = config.Builder.get();
    const producer_config = ConfigBuilder
        .withBootstrapServers("localhost:9092")
        .withLingerMs("5")
        .withBatchSize("10")
        .build();

    const kafka_producer_or_null = Producer.init(producer_config, "foobar-topic");
    assert(kafka_producer_or_null != null);
    if (kafka_producer_or_null) |kafka_producer| {
        assert(@TypeOf(kafka_producer) == Producer);
        kafka_producer.deinit();
    }
}
