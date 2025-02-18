const librdkafka = @cImport({
    @cInclude("librdkafka/rdkafka.h");
});

pub const BrokerMetadata = struct {
    count: usize,
    brokers: [*c]librdkafka.struct_rd_kafka_metadata_broker,
};

pub const TopicMetadata = struct {
    count: usize,
    topics: [*c]librdkafka.struct_rd_kafka_metadata_topic,
};

pub const Metadata = struct {
    const Self = @This();
    _metadata: [*c]const librdkafka.struct_rd_kafka_metadata,

    pub fn deinit(self: Self) void {
        librdkafka.rd_kafka_metadata_destroy(self._metadata);
    }

    pub fn getBrokers(self: Self) BrokerMetadata {
        return .{
            .count = @intCast(self._metadata.*.broker_cnt),
            .brokers = self._metadata.*.brokers,
        };
    }

    pub fn getTopics(self: Self) TopicMetadata {
        return .{
            .count = @intCast(self._metadata.*.topic_cnt),
            .topics = self._metadata.*.topics,
        };
    }
};
