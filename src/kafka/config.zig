const librdkafka = @cImport({
    @cInclude("librdkafka/rdkafka.h");
});
const std = @import("std");
const assert = std.debug.assert;

pub const Config = struct {
    producer: ?*librdkafka.struct_rd_kafka_conf_s,
    topic: ?*librdkafka.struct_rd_kafka_topic_conf_s,
};

pub const Builder = struct {
    _producer_conf: ?*librdkafka.struct_rd_kafka_conf_s,
    _topic_conf: ?*librdkafka.struct_rd_kafka_topic_conf_s,

    pub fn get() Builder {
        const producer_conf: ?*librdkafka.struct_rd_kafka_conf_s = librdkafka.rd_kafka_conf_new();
        if (producer_conf == null) {
            @panic("failed to create config");
        }

        const topic_conf: ?*librdkafka.struct_rd_kafka_topic_conf_s = librdkafka.rd_kafka_topic_conf_new();
        if (topic_conf == null) {
            @panic("Failed to create topic configuration");
        }

        return .{ ._producer_conf = producer_conf, ._topic_conf = topic_conf };
    }

    pub fn withBootstrapServers(self: *Builder, servers: [*c]const u8) *Builder {
        if (librdkafka.rd_kafka_conf_set(self._producer_conf, "bootstrap.servers", servers, null, 0) != librdkafka.RD_KAFKA_CONF_OK) {
            @panic("Failed to set Kafka broker.");
        }
        return self;
    }

    pub fn withBatchSize(self: *Builder, batch_size: [*c]const u8) *Builder {
        if (librdkafka.rd_kafka_conf_set(self._producer_conf, "batch.size", batch_size, null, 0) != librdkafka.RD_KAFKA_CONF_OK) {
            @panic("Failed to set batch size.");
        }
        return self;
    }

    pub fn withLingerMs(self: *Builder, linger_ms: [*c]const u8) *Builder {
        if (librdkafka.rd_kafka_conf_set(self._producer_conf, "linger.ms", linger_ms, null, 0) != librdkafka.RD_KAFKA_CONF_OK) {
            std.log.err("Failed to set linger.ms.", .{});
        }
        return self;
    }

    pub fn build(self: *Builder) Config {
        std.log.info("config initialized", .{});
        return .{ .producer = self._producer_conf, .topic = self._topic_conf };
    }

    pub fn deinit(self: *Builder) void {
        librdkafka.rd_kafka_conf_destroy(self._producer_conf);
    }
};

test "test ConfigBuilder Ok" {
    var ConfigBuilder = Builder.get();
    const conf = ConfigBuilder
        .withBootstrapServers("localhost:9092")
        .withLingerMs("5")
        .withBatchSize("10")
        .build();

    assert(@TypeOf(conf) == Config);
}
