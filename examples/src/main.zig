// examples for documentation - file to be delted!
const std = @import("std");

const kafka = @import("kafka.zig");

fn onMessageSent(message: kafka.Message) void {
    std.log.info("Message sent: {s}", .{message.getPayload()});
}

fn onError(err: i32, reason: [*c]const u8) void {
    std.log.err("error code: {d}; error message: {s}.", .{err, reason});
}

fn plainTextProducer() void {
    var producer_config_builder = kafka.ConfigBuilder.get();
    // https://github.com/confluentinc/librdkafka/blob/master/CONFIGURATION.md#global-configuration-properties
    const producer_conf = producer_config_builder
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

    var topic_config_builder = kafka.TopicBuilder.get();
    // https://github.com/confluentinc/librdkafka/blob/master/CONFIGURATION.md#topic-configuration-properties
    const topic_conf = topic_config_builder
        .with("acks", "all")
        .build();

    const kafka_producer = kafka.Producer.init(producer_conf, topic_conf, "topic-name1");
    defer kafka_producer.deinit();

    kafka_producer.send("some payload", "key");
    kafka_producer.wait(100);
}

const Data = struct { key1: u32, key2: []u8 };

fn jsonProducer() !void {
    var producer_config_builder = kafka.ConfigBuilder.get();
    // https://github.com/confluentinc/librdkafka/blob/master/CONFIGURATION.md#global-configuration-properties
    const producer_conf = producer_config_builder
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

    var topic_config_builder = kafka.TopicBuilder.get();
    // https://github.com/confluentinc/librdkafka/blob/master/CONFIGURATION.md#topic-configuration-properties
    const topic_conf = topic_config_builder
        .with("acks", "all")
        .build();
    kafka.setCb(producer_conf, onMessageSent);
    kafka.setErr(producer_conf, onError);

    const kafka_producer = kafka.Producer.init(producer_conf, topic_conf, "topic-name2");
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

    var consumer_config_builder = kafka.ConfigBuilder.get();
    const consumer_conf = consumer_config_builder
        .with("bootstrap.servers", "localhost:9092")
        .with("group.id", "consumer1")
        .with("auto.offset.reset", "latest")
        .with("enable.auto.commit", "false")
        .with("reconnect.backoff.ms", "100")
        .with("reconnect.backoff.max.ms", "1000")
        .build();
    var kafka_consumer = kafka.Consumer.init(consumer_conf);
    defer kafka_consumer.deinit();

    const topics = [_][]const u8{"topic-name2"};
    kafka_consumer.subscribe(&topics);

    while (true) {
        const message_or_null: ?kafka.Message = kafka_consumer.poll(1000);
        if (message_or_null) |message| {
            std.log.info("offset: {d}", .{message.getOffset()});
            std.log.info("partition: {d}", .{message.getPartition()});
            std.log.info("message length: {d}", .{message.getPayloadLen()});
            std.log.info("key: {s}", .{message.getKey()});
            std.log.info("key length: {d}", .{message.getKeyLen()});
            std.log.info("error code: {d}", .{message.getErrCode()});
            std.log.info("timestamp: {d}", .{message.getTimestamp()});
            const payload: []const u8 = message.getPayload();
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

pub fn listTopics() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var config_builder = kafka.ConfigBuilder.get();
    const conf = config_builder
        .with("bootstrap.servers", "localhost:9092")
        .build();

    const api_client = kafka.AdminApiClient.init(conf);
    defer api_client.deinit();

    var meta = try api_client.getMetadata(allocator);
    defer meta.deinit();
    const topics = meta.listTopics();
    std.log.info("topics count: {d}", .{topics.len});
    std.log.info("topic name: {s}", .{topics[0].name});
    std.log.info("topic partition count: {d}", .{topics[0].partitions.len});
    std.log.info("topic partition id: {d}", .{topics[0].partitions[0].id});
}

pub fn describeTopic() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var config_builder = kafka.ConfigBuilder.get();
    const conf = config_builder
        .with("bootstrap.servers", "localhost:9092")
        .build();

    const api_client = kafka.AdminApiClient.init(conf);
    defer api_client.deinit();

    var meta = try api_client.getMetadata(allocator);
    defer meta.deinit();
    const topic_or_null = meta.describeTopic("topic-name2");
    if (topic_or_null) |topic| {
        std.log.info("topic name: {s}", .{topic.name});
        std.log.info("topic partition count: {d}", .{topic.partitions.len});
        std.log.info("topic partition id: {d}", .{topic.partitions[0].id});
    }
}

pub fn listBrokers() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var config_builder = kafka.ConfigBuilder.get();
    const conf = config_builder
        .with("bootstrap.servers", "localhost:9092")
        .build();

    const api_client = kafka.AdminApiClient.init(conf);
    defer api_client.deinit();

    var meta = try api_client.getMetadata(allocator);
    defer meta.deinit();

    const brokers = meta.listBrokers();
    std.log.info("brokers count: {d}", .{brokers.len});
    std.log.info("host: {s}", .{brokers[0].host});
    std.log.info("port: {d}", .{brokers[0].port});
    std.log.info("brokers id: {d}", .{brokers[0].id});
}

pub fn describeBroker() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var config_builder = kafka.ConfigBuilder.get();
    const conf = config_builder
        .with("bootstrap.servers", "localhost:9092")
        .build();

    const api_client = kafka.AdminApiClient.init(conf);
    defer api_client.deinit();

    var meta = try api_client.getMetadata(allocator);
    defer meta.deinit();

    const host = "localhost";
    const broker_or_null = meta.describeBroker(host);
    if (broker_or_null) |broker| {
        std.log.info("host: {s}", .{broker.host});
        std.log.info("port: {d}", .{broker.port});
        std.log.info("brokers id: {d}", .{broker.id});
    } else {
        std.log.err("broker {s} not found", .{host});
    }
}

pub fn main() !void {
    //plainTextProducer();
    // Admin Api
    try listTopics();
    try describeTopic();
    try listBrokers();
    try describeBroker();

    // Producers & Consumers
    const producer_worker = try std.Thread.spawn(.{}, jsonProducer, .{});
    const consumer_worker = try std.Thread.spawn(.{}, jsonConsumer, .{});
    producer_worker.join();
    consumer_worker.join();
}
