const kafka_client = @cImport({
    @cInclude("librdkafka/rdkafka.h");
});
const std = @import("std");
const config = @import("config.zig");
const assert = std.debug.assert;

pub fn getProducer(conf: ?*kafka_client.struct_rd_kafka_conf_s) ?*kafka_client.rd_kafka_t {
    const kafka_producer: ?*kafka_client.rd_kafka_t = kafka_client.rd_kafka_new(kafka_client.RD_KAFKA_PRODUCER, conf, null, 0);
    if (kafka_producer == null) {
        std.log.err("Failed to create Kafka producer", .{});
        return null;
    }
    std.log.info("kafka producer initialized", .{});
    return kafka_producer;
}

pub fn deinit(producer: ?*kafka_client.rd_kafka_t) void {
    kafka_client.rd_kafka_destroy(producer);
}

test "test get Producer Ok" {
    var ConfigBuilder = config.Builder.get();
    const producer_config = ConfigBuilder
        .withBootstrapServers("localhost:9092")
        .withLingerMs("5")
        .withBatchSize("10")
        .build();

    const kafka_producer = getProducer(producer_config);
    assert(kafka_producer != null);
    assert(@TypeOf(kafka_producer) == ?*kafka_client.rd_kafka_t);
}
