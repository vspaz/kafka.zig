const std = @import("std");

const librdkafka = @cImport({
    @cInclude("librdkafka/rdkafka.h");
});

const config = @import("config.zig");
const m = @import("metadata.zig");
const utils = @import("utils.zig");
const producer = @import("producer.zig");

pub const ApiClient = struct {
    const Self = @This();
    _producer: ?*librdkafka.rd_kafka_t,

    pub fn init(kafka_conf: ?*librdkafka.struct_rd_kafka_conf_s) Self {
        const kafka_producer = producer.Producer.createKafkaProducer(kafka_conf);
        return Self{ ._producer = kafka_producer };
    }

    pub fn deinit(self: Self) void {
        librdkafka.rd_kafka_destroy(self._producer);
        std.log.info("kafka producer deinitialized", .{});
    }

    pub fn getMetadata(self: Self, allocator: std.mem.Allocator) !m.Metadata {
        var metadata: [*c]const librdkafka.struct_rd_kafka_metadata = undefined;
        if (librdkafka.rd_kafka_metadata(self._producer, 1, null, &metadata, 5000) != librdkafka.RD_KAFKA_RESP_ERR_NO_ERROR) {
            std.log.err("Failed to fetch metadata: {s}", .{utils.getLastError()});
        }
        return m.Metadata.init(allocator, metadata);
    }
};

// TODO: mock it
test "test AdminApi.init Ok" {
    var config_builder = config.Builder.get();
    const conf = config_builder
        .with("bootstrap.servers", "localhost:9092")
        .build();

    const api_client = ApiClient.init(conf);
    api_client.deinit();
    std.debug.assert(@TypeOf(api_client) == ApiClient);
}

// TODO: mock it
test "test Metadata.listBrokers Ok" {
    var config_builder = config.Builder.get();
    const conf = config_builder
        .with("bootstrap.servers", "localhost:9092")
        .build();

    const api_client = ApiClient.init(conf);
    defer api_client.deinit();

    const allocator = std.testing.allocator;
    var meta = try api_client.getMetadata(allocator);
    defer meta.deinit();
    const brokers = meta.listBrokers();
    std.debug.assert(std.mem.eql(u8, "localhost", brokers[0].host));
    std.debug.assert(1 == brokers.len);
    std.debug.assert(std.mem.eql(u8, "localhost", brokers[0].host));
    std.debug.assert(9092 == brokers[0].port);
    std.debug.assert(1 == brokers[0].id);
}

// TODO: mock it
test "test Metadata.listTopics Ok" {
    var config_builder = config.Builder.get();
    const conf = config_builder
        .with("bootstrap.servers", "localhost:9092")
        .build();

    const api_client = ApiClient.init(conf);
    defer api_client.deinit();

    const allocator = std.testing.allocator;
    var meta = try api_client.getMetadata(allocator);
    defer meta.deinit();
    const topics = meta.listTopics();
    std.debug.assert(3 == topics.len);
    std.debug.assert(std.mem.eql(u8, "topic-name2", topics[0].name));
    std.debug.assert(0 == topics[0].partitions[0].id);
    std.debug.assert(std.mem.eql(u8, "topic-name2", topics[0].name));
}
