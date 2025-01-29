const std = @import("std");
const config = @import("kafka/config.zig");
const producer = @import("kafka/producer.zig");

pub fn main() !void {
    var ConfigBuilder = config.Builder.get();
    const producer_config = ConfigBuilder
        .withBootstrapServers("localhost:9092")
        .withLingerMs("5")
        .withBatchSize("10")
        .build();

    const kafka_producer = producer.Producer.init(producer_config, "topic-name");
    defer kafka_producer.deinit();
    kafka_producer.send("some payload", "key");
    kafka_producer.wait();
}

test {
    std.testing.refAllDecls(@This());
}
