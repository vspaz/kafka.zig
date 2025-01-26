const std = @import("std");
const config = @import("kafka/producer/config.zig");

pub fn main() !void {
    var configBuilder = config.Builder.get();
    _ = configBuilder
        .withBootstrapServers("localhost:9092")
        .withLingerMs("5")
        .withBatchSize("10")
        .build();
}

test {
    std.testing.refAllDecls(@This());
}
