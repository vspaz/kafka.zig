const librdkafka = @cImport({
    @cInclude("librdkafka/rdkafka.h");
});
const std = @import("std");

pub fn getTopicConfig() ?*librdkafka.struct_rd_kafka_topic_conf_s {
    const topic_conf: ?*librdkafka.struct_rd_kafka_topic_conf_s = librdkafka.rd_kafka_topic_conf_new();
    if (topic_conf == null) {
        @panic("Failed to create topic configuration");
    }
    return topic_conf;
}

pub fn createTopic(producer: ?*librdkafka.rd_kafka_t, topic_conf: ?*librdkafka.struct_rd_kafka_topic_conf_s, topic_name: [*]const u8) ?*librdkafka.struct_rd_kafka_topic_s {
    const kafka_topic: ?*librdkafka.struct_rd_kafka_topic_s = librdkafka.rd_kafka_topic_new(producer, topic_name, topic_conf);
    if (kafka_topic == null) {
        @panic("Failed to create Kafka topic");
    }
    return kafka_topic;
}

const Builder = struct {
    _topic_conf: ?*librdkafka.struct_rd_kafka_topic_conf_s,

    pub fn init() Builder {
        return .{ ._topic_conf = getTopicConfig() };
    }

    fn setTopicConfigParam(self: *Builder, topic_param: [*c]const u8, topic_value: [*c]const u8) *Builder {
        var error_message: [512]u8 = undefined;
        if (librdkafka.rd_kafka_topic_conf_set(self._topic_conf, topic_param, topic_value, &error_message, error_message.len) != librdkafka.RD_KAFKA_CONF_OK) {
            @panic(&error_message);
        }
    }

    pub fn withBootstrapServers(self: *Builder, request_required_acks: [*c]const u8) *Builder {
        setTopicConfigParam(self, "request.required.acks", request_required_acks);
        return self;
    }

    pub fn build(self: *Builder) ?*librdkafka.struct_rd_kafka_topic_conf_s {
        return self._topic_conf;
    }
};
