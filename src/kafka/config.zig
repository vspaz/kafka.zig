const librdkafka = @cImport({
    @cInclude("librdkafka/rdkafka.h");
});
const std = @import("std");
const assert = std.debug.assert;

// https://github.com/confluentinc/librdkafka/blob/master/CONFIGURATION.md#global-configuration-properties
pub const Config = struct {
    producer: ?*librdkafka.struct_rd_kafka_conf_s,
};

pub const Builder = struct {
    _producer_conf: ?*librdkafka.struct_rd_kafka_conf_s,

    pub fn get() Builder {
        return .{ ._producer_conf = getProducerConfig() };
    }

    fn getProducerConfig() ?*librdkafka.struct_rd_kafka_conf_s {
        const producer_conf: ?*librdkafka.struct_rd_kafka_conf_s = librdkafka.rd_kafka_conf_new();
        if (producer_conf == null) {
            @panic("failed to create config");
        }
        return producer_conf;
    }

    fn setConfigParameter(self: *Builder, param: [*c]const u8, value: [*c]const u8) void {
        var error_message: [512]u8 = undefined;
        if (librdkafka.rd_kafka_conf_set(self._producer_conf, param, value, &error_message, error_message.len) != librdkafka.RD_KAFKA_CONF_OK) {
            @panic(&error_message);
        }
    }

    pub fn with(self: *Builder, param: [*c]const u8, value: [*c]const u8) *Builder {
        setConfigParameter(self, param, value);
        return self;
    }

    pub fn build(self: *Builder) ?*librdkafka.struct_rd_kafka_conf_s {
        std.log.info("config initialized", .{});
        return self._producer_conf;
    }
};

test "test ConfigBuilder Ok" {
    var ConfigBuilder = Builder.get();
    const conf = ConfigBuilder
        .with("bootstrap.servers", "localhost:9092")
        .with("batch.num.messages", "100")
        .with("linger.ms", "100")
        .with("compression.codec", "snappy")
        .with("batch.size", "16384")
        .build();

    assert(@TypeOf(conf) == ?*librdkafka.struct_rd_kafka_conf_s);
}
