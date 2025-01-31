const std = @import("std");
const config = @import("kafka/config.zig");
const producer = @import("kafka/producer.zig");

pub fn main() !void {
    var ConfigBuilder = config.Builder.get();
    const conf = ConfigBuilder
        .with("bootstrap.servers", "localhost:9092")
        .with("batch.num.messages", "10")
        .with("linger.ms", "100")
        .with("compression.codec", "snappy")
        .with("batch.size", "16384")
        .build();

    const kafka_producer = producer.Producer.init(conf, "topic-name");
    defer kafka_producer.deinit();

    kafka_producer.send("some payload", "key");
    kafka_producer.wait(100);
}

test {
    std.testing.refAllDecls(@This());
}
