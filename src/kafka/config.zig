const librdkafka = @cImport({
    @cInclude("librdkafka/rdkafka.h");
});
const std = @import("std");
const assert = std.debug.assert;

pub const Config = struct {
    producer: ?*librdkafka.struct_rd_kafka_conf_s,
};

pub const Builder = struct {
    _producer_conf: ?*librdkafka.struct_rd_kafka_conf_s,

    pub fn get() Builder {
        const producer_conf: ?*librdkafka.struct_rd_kafka_conf_s = librdkafka.rd_kafka_conf_new();
        if (producer_conf == null) {
            @panic("failed to create config");
        }

        return .{ ._producer_conf = producer_conf };
    }

    fn setConfigParameter(self: *Builder, config_param: [*c]const u8, config_value: [*c]const u8) void {
        var error_message: [512]u8 = undefined;
        if (librdkafka.rd_kafka_conf_set(self._producer_conf, config_param, config_value, &error_message, error_message.len) != librdkafka.RD_KAFKA_CONF_OK) {
            @panic(&error_message);
        }
    }

    pub fn withBootstrapServers(self: *Builder, servers: [*c]const u8) *Builder {
        setConfigParameter(self, "bootstrap.servers", servers);
        return self;
    }

    pub fn withBatchSize(self: *Builder, batch_size: [*c]const u8) *Builder {
        setConfigParameter(self, "batch.size", batch_size);
        return self;
    }

    pub fn withBatchNumMessages(self: *Builder, batch_num_messages: [*c]const u8) *Builder {
        setConfigParameter(self, "batch.num.messages", batch_num_messages);
        return self;
    }

    pub fn withLingerMs(self: *Builder, linger_ms: [*c]const u8) *Builder {
        setConfigParameter(self, "linger.ms", linger_ms);
        return self;
    }

    pub fn withCompressionCodec(self: *Builder, codec: [*c]const u8) *Builder {
        setConfigParameter(self, "compression.codec", codec);
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
        .withBootstrapServers("localhost:9092")
        .withLingerMs("5")
        .withBatchSize("16384")
        .build();

    assert(@TypeOf(conf) == ?*librdkafka.struct_rd_kafka_conf_s);
}
