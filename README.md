## kafka-zig

### install dependencies

```shell
sudo apt-get update && sudo apt-get upgrade -y
sudo apt-get install librdkafka-dev
```

### Simple Zig Kafka producer using C/C++ librdkafka.
```zig
const std = @import("std");
const config = @import("kafka/config.zig");
const producer = @import("kafka/producer.zig");
const topic = @import("kafka/topic.zig");

pub fn main() !void {
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

    const kafka_producer = producer.Producer.init(producer_conf, topic_conf, "topic-name");
    defer kafka_producer.deinit();

    kafka_producer.send("some payload", "key");
    kafka_producer.wait(100);
}
```