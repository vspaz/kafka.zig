const kafka = @cImport({
    @cInclude("librdkafka/rdkafka.h");
});
const std = @import("std");
const assert = std.debug.assert;

pub const Builder = struct {
    _conf: ?*kafka.struct_rd_kafka_conf_s,

    pub fn get() Builder {
        const conf = kafka.rd_kafka_conf_new();
        if (conf == null) {
            std.debug.print("failed to create config", .{});
        }
        return .{ ._conf = conf };
    }

    pub fn withBootstrapServers(self: *Builder, servers: [*c]const u8) *Builder {
        if (kafka.rd_kafka_conf_set(self._conf, "bootstrap.servers", servers, null, 0) != kafka.RD_KAFKA_CONF_OK) {
            std.debug.print("Failed to set Kafka broker.\n", .{});
        }
        return self;
    }

    pub fn withBatchSize(self: *Builder, batch_size: [*c]const u8) *Builder {
        if (kafka.rd_kafka_conf_set(self._conf, "batch.size", batch_size, null, 0) != kafka.RD_KAFKA_CONF_OK) {
            std.debug.print("Failed to set batch size.\n", .{});
        }
        return self;
    }

    pub fn withLingerMs(self: *Builder, linger_ms: [*c]const u8) *Builder {
        if (kafka.rd_kafka_conf_set(self._conf, "linger.ms", linger_ms, null, 0) != kafka.RD_KAFKA_CONF_OK) {
            std.debug.print("Failed to set linger.ms.\n", .{});
        }
        return self;
    }

    pub fn build(self: *Builder) ?*kafka.rd_kafka_conf_t {
        std.debug.print("config initialized\n", .{});
        return self._conf;
    }
};

pub fn deinit(config: ?*kafka.struct_rd_kafka_conf_s) void {
    kafka.rd_kafka_conf_destroy(config);
}

test "test ConfigBuilder Ok" {
    var ConfigBuilder = Builder.get();
    const producer_config = ConfigBuilder
        .withBootstrapServers("localhost:9092")
        .withLingerMs("5")
        .withBatchSize("10")
        .build();

    defer deinit(producer_config);
}
