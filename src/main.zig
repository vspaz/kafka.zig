const std = @import("std");
const config = @import("kafka/config.zig");
const producer = @import("kafka/producer.zig");
const consumer = @import("kafka/consumer.zig");
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
        .with("acks", "all")
        .build();

    const kafka_producer = producer.Producer.init(producer_conf, topic_conf, "topic-name1");
    defer kafka_producer.deinit();

    kafka_producer.send("some payload", "key");
    kafka_producer.wait(100);
}

const Data = struct { key1: u32, key2: []u8 };

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
        .with("acks", "all")
        .build();

    const kafka_producer = producer.Producer.init(producer_conf, topic_conf, "topic-name2");
    defer kafka_producer.deinit();

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    for (0..100) |_| {
        const message = .{ .key1 = 100, .key2 = "kafka" };
        const encoded_message = try std.json.stringifyAlloc(allocator, message, .{});
        defer allocator.free(encoded_message);

        kafka_producer.send(encoded_message, "key");
        kafka_producer.wait(100);
        std.time.sleep(1_000_000_000);
    }
}

fn jsonConsumer() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var consumer_config_builder = config.Builder.get();
    const consumer_conf = consumer_config_builder
        .with("bootstrap.servers", "localhost:9092")
        .with("group.id", "consumer1")
        .with("auto.offset.reset", "earliest")
        .with("auto.commit.interval.ms", "5000")
        .build();
    var kafka_consumer = consumer.Consumer.init(consumer_conf);
    defer kafka_consumer.deinit();

    const topics = [_][]const u8{"topic-name2"};
    kafka_consumer.subscribe(&topics);

    while (true) {
        const msg = kafka_consumer.poll(1000);
        if (msg) |message| {
            const payload: []const u8 = @as([*]u8, @ptrCast(message.payload))[0..message.len];
            std.log.info("Received message: {s}", .{payload});
            const parsed_payload = try std.json.parseFromSlice(Data, allocator, payload, .{});
            defer parsed_payload.deinit();
            std.log.info("parsed value: {s}", .{parsed_payload.value.key2});
            kafka_consumer.commitOffsetOnEvery(10, message); // or kafka_consumer.commitOffset(message) to commit on every message.
        }
    }
    kafka_consumer.unsubscribe();
    kafka_consumer.close();
}

pub fn main() !void {
    // plainTextProducer();
    const producer_worker = try std.Thread.spawn(.{}, jsonProducer, .{});
    const consumer_worker = try std.Thread.spawn(.{}, jsonConsumer, .{});
    producer_worker.join();
    consumer_worker.join();
}

test {
    std.testing.refAllDecls(@This());
}
