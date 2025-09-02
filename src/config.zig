const std = @import("std");

const librdkafka = @import("cimport.zig").librdkafka;

// https://github.com/confluentinc/librdkafka/blob/master/CONFIGURATION.md#global-configuration-properties
pub const Builder = struct {
    const Self = @This();
    _kafka_conf: ?*librdkafka.struct_rd_kafka_conf_s,

    pub inline fn get() Self {
        return Self{ ._kafka_conf = getProducerConf() };
    }

    inline fn getProducerConf() ?*librdkafka.struct_rd_kafka_conf_s {
        const producer_conf: ?*librdkafka.struct_rd_kafka_conf_s = librdkafka.rd_kafka_conf_new();
        if (producer_conf == null) {
            @branchHint(.unlikely);
            @panic("failed to create config");
        }
        return producer_conf;
    }

    inline fn setConfigParameter(self: Self, param: [*c]const u8, value: [*c]const u8) void {
        var error_message: [512]u8 = undefined;
        if (librdkafka.rd_kafka_conf_set(self._kafka_conf, param, value, &error_message, error_message.len) != librdkafka.RD_KAFKA_CONF_OK) {
            @branchHint(.unlikely);
            @panic(&error_message);
        }
    }

    pub inline fn with(self: Self, param: [*c]const u8, value: [*c]const u8) Self {
        setConfigParameter(self, param, value);
        return self;
    }

    pub inline fn build(self: Self) ?*librdkafka.struct_rd_kafka_conf_s {
        return self._kafka_conf;
    }
};

test "test Producer ConfigBuilder Ok" {
    var ConfigBuilder = Builder.get();
    const conf = ConfigBuilder
        .with("debug", "all")
        .with("bootstrap.servers", "localhost:9092")
        .with("enable.idempotence", "true")
        .with("batch.num.messages", "10")
        .with("reconnect.backoff.ms", "1000")
        .with("reconnect.backoff.max.ms", "5000")
        .with("transaction.timeout.ms", "10000")
        .with("linger.ms", "100")
        .with("delivery.timeout.ms", "1800000")
        .with("compression.codec", "snappy")
        .with("batch.size", "16384")
        .build();

    std.debug.assert(@TypeOf(conf) == ?*librdkafka.struct_rd_kafka_conf_s);
}

test "test Consumer ConfigBuilder Ok" {
    var consumer_config_builder = Builder.get();
    const conf = consumer_config_builder
        .with("bootstrap.servers", "localhost:9092")
        .with("group.id", "consumer1")
        .with("auto.offset.reset", "latest")
        .with("enable.auto.commit", "false")
        .with("isolation.level", "read_committed")
        .with("reconnect.backoff.max.ms", "1000")
        .with("reconnect.backoff.max.ms", "5000")
        .build();

    std.debug.assert(@TypeOf(conf) == ?*librdkafka.struct_rd_kafka_conf_s);
}
