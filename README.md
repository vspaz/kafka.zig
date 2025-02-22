# kafka.zig
`kafka.zig` is the **Apache Kafka Zig** client library built on top of **C/C++** [librdkafka](https://docs.confluent.io/platform/current/clients/librdkafka/html/index.html).
This lib makes it plain simple to write your own **Apache Kafka** producers and consumers in **Zig**.
`kafka.zig` is also very lean and efficient.
## Installation
> [!IMPORTANT]
> `kafka.zig` relies on C/C++ `librdkafka`, so we need to install it first before we start using `kafka.zig`. 
> The good news is that's the only dependency that's required by `kafka.zig`.
1. install `librdkafka`

:penguin: Linux - .deb-based, e.g., Debian, Ubuntu etc.
```shell
apt-get install librdkafka-dev
```
:penguin: Linux - .rpm-based, e.g., RedHat, Fedora and other RHEL derivatives.
```shell
yum install librdkafka-devel
```
Mac OSX
```shell
brew install librdkafka
```
2. Run the following command inside your project:
```shell
 zig fetch --save git+https://github.com/vspaz/kafka.zig.git#main
```
it should add the following dependency to your project _build.zig.zon_ file, e.g.
```zig
.dependencies = .{
    .@"kafka.zig" = .{
        .url = "git+https://github.com/vspaz/kafka.zig.git?ref=main#c3d2d726ebce1daea58c12e077a90e7afdc60f88",
        .hash = "1220367e8cb4867b60e2bfa3e2f3663bc0669a4b6899650abcc82fc9b8763fd64050",
    },
},
```
3. Navigate to _build.zig_ file located in the root directory and add the following 3 lines as shown below:
```zig
 const exe = b.addExecutable(.{
        .name = "yourproject",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    
    // add these 3 lines! 
    const kafkazig = b.dependency("kafka.zig", .{});
    exe.root_module.addImport("kafka.zig", kafkazig.module("kafka.zig"));
    exe.linkSystemLibrary("rdkafka");
```
4. Test the project build with `zig build`
There should be no error!
5. Import `kafka.zig` in your code as:
```zig
const kafka = @import("kafka.zig");
```
and you're good to go! :rocket:
## Configuration
### Producer/Consumer
Configuration parameters can be set via `kafka.ConfigBuilder`
An example of using `kafka.ConfigBuilder`
```zig
const kafka = @import("kafka.zig");

pub fn main() !void {
    var producer_config_builder = kafka.ConfigBuilder.get();
    const producer_conf = producer_config_builder
        .with("bootstrap.servers", "localhost:9092")
        .with("enable.idempotence", "true")
        .with("batch.num.messages", "10")
        .with("reconnect.backoff.ms", "1000")
        .with("reconnect.backoff.max.ms", "5000")
        .with("transaction.timeout.ms", "10000")
        .with("linger.ms", "100")
        .with("delivery.timeout.ms", "1800000")
        .with("compression.codec", "snappy")
        .with("batch.size", "16384")    
        .build();
}
```
>[!TIP]
> see all possible config options at:
https://github.com/confluentinc/librdkafka/blob/master/CONFIGURATION.md#global-configuration-properties
### Topic
A topic is configured similarly to Producer/Consumer, but using `kafka.TopicBuilder` class.

An example of configuring a topic via `kafka.TopicBuilder`.
```zig

pub fn main() !void {
    var topic_config_builder = kafka.TopicBuilder.get();
    const topic_conf = topic_config_builder
        .with("acks", "all")
        .build();
}
```
> [!TIP]
> See all possible config options for a topic configuration at: https://github.com/confluentinc/librdkafka/blob/master/CONFIGURATION.md#topic-configuration-properties.
## Producers
A simple Zig Apache Kafka producer sending plain text data.
```zig
const kafka = @import("kafka.zig");

fn plainTextProducer() void {
    var producer_config_builder = kafka.ConfigBuilder.get();
    const producer_conf = producer_config_builder
        .with("bootstrap.servers", "localhost:9092")
        .with("enable.idempotence", "true")
        .with("batch.num.messages", "10")
        .with("reconnect.backoff.ms", "1000")
        .with("reconnect.backoff.max.ms", "5000")
        .with("transaction.timeout.ms", "10000")
        .with("linger.ms", "100")
        .with("delivery.timeout.ms", "1800000")
        .with("compression.codec", "snappy")
        .with("batch.size", "16384")    
        .build();

    var topic_config_builder = kafka.TopicBuilder.get();
    const topic_conf = topic_config_builder
        .with("acks", "all")
        .build();

    const kafka_producer = kafka.Producer.init(producer_conf, topic_conf, "topic-name1");
    defer kafka_producer.deinit();

    kafka_producer.send("some payload", "key");
    kafka_producer.wait(100);
}

pub fn main() !void {
    plainTextProducer();
}
```
An example of a **Kafka Zig** producer, producing JSON or binary data.
```zig
const std = @import("std");
const kafka = @import("kafka.zig");

fn jsonProducer() !void {
    var producer_config_builder = kafka.ConfigBuilder.get();
    const producer_conf = producer_config_builder
        .with("bootstrap.servers", "localhost:9092")
        .with("enable.idempotence", "true")
        .with("batch.num.messages", "10")
        .with("reconnect.backoff.ms", "1000")
        .with("reconnect.backoff.max.ms", "5000")
        .with("transaction.timeout.ms", "10000")
        .with("linger.ms", "100")
        .with("delivery.timeout.ms", "1800000")
        .with("compression.codec", "snappy")
        .with("batch.size", "16384")
        .build();

    var topic_config_builder = kafka.TopicBuilder.get();
    const topic_conf = topic_config_builder
        .with("acks", "all")
        .build();

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
    }
}

pub fn main() !void {
    try jsonProducer();
}
```
### Callbacks
If you wish to set a producer callback, you can do it with `kafka.setCb` as follows:
```zig
const kafka = @import("kafka.zig");

fn onMessageSent(message: kafka.Message) void {
    std.log.info("Message sent: {s}", .{message.getPayload()});
}

fn producer() void {
    var producer_config_builder = kafka.ConfigBuilder.get();
    const producer_conf = producer_config_builder
        .with("bootstrap.servers", "localhost:9092")
        .build();
    
    kafka.setCb(producer_conf, onMessageSent);
}
```
> [!NOTE] 
> The callback is a part of producer configuration and should be set before producer is initialized!
## Consumers
An example of a **Zig Kafka** consumer, consuming JSON or binary data.
```zig
const std = @import("std");
const kafka = @import("kafka.zig");

const Data = struct { key1: u32, key2: []u8 };

fn jsonConsumer() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var consumer_config_builder = kafka.ConfigBuilder.get();
    const consumer_conf = consumer_config_builder
        .with("debug", "all")
        .with("bootstrap.servers", "localhost:9092")
        .with("group.id", "consumer1")
        .with("auto.offset.reset", "latest")
        .with("enable.auto.commit", "false")
        .with("isolation.level", "read_committed")
        .with("rreconnect.backoff.ms", "100")
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
    // when the work is done call 'unsubscribe' & 'close'
    kafka_consumer.unsubscribe();
    kafka_consumer.close();
}

pub fn main() !void {
    const producer_worker = try std.Thread.spawn(.{}, jsonProducer, .{});
    const consumer_worker = try std.Thread.spawn(.{}, jsonConsumer, .{});
    producer_worker.join();
    consumer_worker.join();
}
```
## AdminApiClient & Metadata
TODO!: to be added

## Examples
Please, refer to the examples [section](https://github.com/vspaz/kafka.zig/blob/main/examples/README.md).

## Useful references

- [Kafka global configuration](https://github.com/confluentinc/librdkafka/blob/master/CONFIGURATION.md#global-configuration-properties)
- [Topic configuration]( https://github.com/confluentinc/librdkafka/blob/master/CONFIGURATION.md#topic-configuration-properties)
- [Introduction to librdkafka](https://github.com/confluentinc/librdkafka/blob/master/INTRODUCTION.md).
