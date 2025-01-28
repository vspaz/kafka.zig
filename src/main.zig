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
    const kafka_producer_or_null = producer.Producer.init(producer_config);
    if (kafka_producer_or_null) |kafka_producer| {
        defer kafka_producer.deinit();
    }
}

test {
    std.testing.refAllDecls(@This());
}
