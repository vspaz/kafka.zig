const std = @import("std");
const config = @import("kafka/producer/config.zig");

pub fn main() !void {
    var config_builder = config.Builder.get();
    const producer_config = config_builder
        .withBootstrapServers("localhost:9092")
        .withLingerMs("5")
        .withBatchSize("10")
        .build();

    defer config.deinit(producer_config);
}

test {
    std.testing.refAllDecls(@This());
}
