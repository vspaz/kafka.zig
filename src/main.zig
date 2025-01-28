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
    const kafka_producer = producer.getProducer(producer_config);
    defer producer.deinit(kafka_producer);
}

test {
    std.testing.refAllDecls(@This());
}
