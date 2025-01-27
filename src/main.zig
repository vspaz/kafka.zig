const std = @import("std");
const config = @import("kafka/config.zig");

pub fn main() !void {
    var ConfigBuilder = config.Builder.get();
    const producer_config = ConfigBuilder
        .withBootstrapServers("localhost:9092")
        .withLingerMs("5")
        .withBatchSize("10")
        .build();

    defer config.deinit(producer_config);
}

test {
    std.testing.refAllDecls(@This());
}
