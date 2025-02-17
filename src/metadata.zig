const librdkafka = @cImport({
    @cInclude("librdkafka/rdkafka.h");
});

pub const Metadata = struct {
    const Self = @This();
    _metadata: [*c]const librdkafka.struct_rd_kafka_metadata,

    pub fn init() Self {
        return Self{ ._metadata = undefined };
    }

    pub fn deinit(self: Self) void {
        librdkafka.rd_kafka_metadata_destroy(self._metadata);
    }

    pub fn getBrokerCount(self: Self) usize {
        return @intCast(self._metadata.*.broker_cnt);
    }

    pub fn getBrokers(self: Self) [*c]librdkafka.struct_rd_kafka_metadata_broker {
        return self._metadata.*.brokers;
    }
};
