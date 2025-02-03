# kafka.zig
A simple-to-use Kafka Zig library built on top of **C/C++** `librdkafka`.

## Dependencies
Linux - Debian/Ubuntu.
1. install C/C++ `librdkafka`.

```shell
sudo apt-get update && sudo apt-get upgrade -y
sudo apt-get install librdkafka-dev
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
3. Navigate to _build.zig_ and add the following 3 lines as shown below:
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

## How-to

Import _kafka.zig_ as a dependency in your code as follows:
```zig
const kafka = @import("kafka.zig");
```
and you're good to go!

### Configuration
#### Producer/Consumer

Configuration parameters can be set via `kafka.ConfigBuilder`
see all possible config options at:

https://github.com/confluentinc/librdkafka/blob/master/CONFIGURATION.md#global-configuration-properties

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

#### Topic
A topic is configured similarly to Producer/Consumer, but using `kafka.TopicBuilder` class.
See all possible config options for a topic configuration at: 

https://github.com/confluentinc/librdkafka/blob/master/CONFIGURATION.md#topic-configuration-properties.

An example of configuring a topic via `kafka.TopicBuilder`.
```zig

pub fn main() !void {
    var topic_config_builder = kafka.TopicBuilder.get();
    const topic_conf = topic_config_builder
        .with("acks", "all")
        .build();
}
```
### Producer
#### a simple producer sending plain text data.
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

### Producer, sending JSON or binary data.
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

### Consumer, consuming JSON or binary data.

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
        .with("bootstrap.servers", "localhost:9092")
        .with("group.id", "consumer1")
        .with("auto.offset.reset", "latest")
        .with("enable.auto.commit", "false")
        .with("isolation.level", "read_committed")
        .with("reconnect.backoff.max.ms", "1000")
        .with("reconnect.backoff.max.ms", "5000")
        .build();
    var kafka_consumer = kafka.Consumer.init(consumer_conf);
    defer kafka_consumer.deinit();

    const topics = [_][]const u8{"topic-name2"};
    kafka_consumer.subscribe(&topics);

    while (true) {
        const msg = kafka_consumer.poll(1000);
        if (msg) |message| {
            const payload: []const u8 = kafka.toSlice(message);
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
    const producer_worker = try std.Thread.spawn(.{}, jsonProducer, .{});
    const consumer_worker = try std.Thread.spawn(.{}, jsonConsumer, .{});
    producer_worker.join();
    consumer_worker.join();
}
```
