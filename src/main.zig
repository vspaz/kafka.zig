const std = @import("std");
const config = @import("kafka/config.zig");
const producer = @import("kafka/producer.zig");
const topic = @import("kafka/topic.zig");

fn plainTextProducer() void {
    var producer_config_builder = config.Builder.get();
    // https://github.com/confluentinc/librdkafka/blob/master/CONFIGURATION.md#global-configuration-properties
    const producer_conf = producer_config_builder
        .with("bootstrap.servers", "localhost:9092")
        .with("batch.num.messages", "10")
        .with("linger.ms", "100")
        .with("compression.codec", "snappy")
        .with("batch.size", "16384")
        .build();

    var topic_config_builder = topic.Builder.get();
    // https://github.com/confluentinc/librdkafka/blob/master/CONFIGURATION.md#topic-configuration-properties
    const topic_conf = topic_config_builder
        .with("request.required.acks", "all")
        .build();

    const kafka_producer = producer.Producer.init(producer_conf, topic_conf, "topic-name1");
    defer kafka_producer.deinit();

    kafka_producer.send("some payload", "key");
    kafka_producer.wait(100);
}

fn jsonProducer() !void {
    var producer_config_builder = config.Builder.get();
    // https://github.com/confluentinc/librdkafka/blob/master/CONFIGURATION.md#global-configuration-properties
    const producer_conf = producer_config_builder
        .with("bootstrap.servers", "localhost:9092")
        .with("batch.num.messages", "10")
        .with("linger.ms", "100")
        .with("compression.codec", "snappy")
        .with("batch.size", "16384")
        .build();

    var topic_config_builder = topic.Builder.get();
    // https://github.com/confluentinc/librdkafka/blob/master/CONFIGURATION.md#topic-configuration-properties
    const topic_conf = topic_config_builder
        .with("request.required.acks", "all")
        .build();

    const kafka_producer = producer.Producer.init(producer_conf, topic_conf, "topic-name2");
    defer kafka_producer.deinit();

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const message = .{ .key1 = 100, .key2 = "kafka" };
    const encoded_message = try std.json.stringifyAlloc(allocator, message, .{});
    defer allocator.free(encoded_message);

    kafka_producer.send(encoded_message, "key");
    kafka_producer.wait(100);
}

pub fn main() !void {
    plainTextProducer();
    try jsonProducer();
}

test {
    std.testing.refAllDecls(@This());
}
