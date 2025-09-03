const std = @import("std");

const librdkafka = @import("cimport.zig").librdkafka;

pub fn createTopic(client: ?*librdkafka.rd_kafka_t, topic_conf: ?*librdkafka.struct_rd_kafka_topic_conf_s, topic_name: [*]const u8) ?*librdkafka.struct_rd_kafka_topic_s {
    const kafka_topic: ?*librdkafka.struct_rd_kafka_topic_s = librdkafka.rd_kafka_topic_new(client, topic_name, topic_conf);
    if (kafka_topic == null) {
        @branchHint(.unlikely);
        @panic("Failed to create Kafka topic");
    }
    return kafka_topic;
}

// https://github.com/confluentinc/librdkafka/blob/master/CONFIGURATION.md#topic-configuration-properties
pub const Builder = struct {
    const Self = @This();
    _topic_conf: ?*librdkafka.struct_rd_kafka_topic_conf_s,

    pub fn get() Self {
        return Self{ ._topic_conf = getTopicConf() };
    }

    pub fn getTopicConf() ?*librdkafka.struct_rd_kafka_topic_conf_s {
        const topic_conf: ?*librdkafka.struct_rd_kafka_topic_conf_s = librdkafka.rd_kafka_topic_conf_new();
        if (topic_conf == null) {
            @branchHint(.unlikely);
            @panic("Failed to create topic configuration");
        }
        return topic_conf;
    }

    fn setTopicConfigParam(self: Self, topic_param: [*c]const u8, topic_value: [*c]const u8) void {
        var error_message: [512]u8 = undefined;
        if (librdkafka.rd_kafka_topic_conf_set(self._topic_conf, topic_param, topic_value, &error_message, error_message.len) != librdkafka.RD_KAFKA_CONF_OK) {
            @branchHint(.unlikely);
            @panic(&error_message);
        }
    }

    pub inline fn with(self: Self, param: [*c]const u8, value: [*c]const u8) Self {
        setTopicConfigParam(self, param, value);
        return self;
    }

    pub inline fn build(self: Self) ?*librdkafka.struct_rd_kafka_topic_conf_s {
        return self._topic_conf;
    }
};

test "test get topic Builder Ok" {
    var TopicConfigBuilder = Builder.get();
    const topic_conf = TopicConfigBuilder
        .with("acks", "all")
        .build();

    std.debug.assert(@TypeOf(topic_conf) == ?*librdkafka.struct_rd_kafka_topic_conf_s);
}
