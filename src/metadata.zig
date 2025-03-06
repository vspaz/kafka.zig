const std = @import("std");

const librdkafka = @cImport({
    @cInclude("librdkafka/rdkafka.h");
});

pub const Broker = struct {
    id: i32,
    host: []u8,
    port: i32,

    fn init(broker: librdkafka.rd_kafka_metadata_broker) Broker {
        return .{
            .id = broker.id,
            .host = std.mem.span(broker.host),
            .port = broker.port,
        };
    }
};

const BrokerMetadata = struct {
    const Self = @This();
    count: usize,
    brokers: [*c]librdkafka.struct_rd_kafka_metadata_broker,

    fn toArray(self: Self, allocator: std.mem.Allocator) ![]Broker {
        var brokers: []Broker = try allocator.alloc(Broker, self.count);
        for (0..self.count) |i| {
            brokers[i] = Broker.init(self.brokers[i]);
        }
        return brokers;
    }
};

pub const Partition = struct {
    id: i32,
    leader: i32,
    insync_replicas: []i32,
    replicas: []i32,
    error_code: u64,

    fn init(partition: librdkafka.struct_rd_kafka_metadata_partition) Partition {
        return .{
            .id = partition.id,
            .leader = partition.leader,
            .insync_replicas = partition.isrs[0..@intCast(partition.isr_cnt)],
            .replicas = partition.replicas[0..@intCast(partition.replica_cnt)],
            .error_code = @intCast(partition.err),
        };
    }
};

pub const Topic = struct {
    name: []u8,
    partitions: []Partition,
    error_code: i32,

    fn init(topic: librdkafka.struct_rd_kafka_metadata_topic, allocator: std.mem.Allocator) !Topic {
        const partition_count: usize = @intCast(topic.partition_cnt);
        var partitions: []Partition = try allocator.alloc(Partition, partition_count);
        for (0..partition_count) |i| {
            partitions[i] = Partition.init(topic.partitions[i]);
        }

        return .{
            .name = std.mem.span(topic.topic),
            .partitions = partitions,
            .error_code = @intCast(topic.err),
        };
    }
};

const TopicMetadata = struct {
    const Self = @This();
    count: usize,
    topics: [*c]librdkafka.struct_rd_kafka_metadata_topic,

    fn toArray(self: Self, allocator: std.mem.Allocator) ![]Topic {
        var topics: []Topic = try allocator.alloc(Topic, self.count);
        for (0..self.count) |i| {
            topics[i] = try Topic.init(self.topics[i], allocator);
        }
        return topics;
    }
};

pub const Metadata = struct {
    const Self = @This();
    _allocator: std.mem.Allocator,
    _metadata: [*c]const librdkafka.struct_rd_kafka_metadata,
    _topics: []Topic,
    _brokers: []Broker,

    pub fn init(allocator: std.mem.Allocator, metadata: [*c]const librdkafka.struct_rd_kafka_metadata) !Metadata {
        const broker_metadata = BrokerMetadata{
            .count = @intCast(metadata.*.broker_cnt),
            .brokers = metadata.*.brokers,
        };

        const brokers = try broker_metadata.toArray(allocator);

        const topic_metadata = TopicMetadata{
            .count = @intCast(metadata.*.topic_cnt),
            .topics = metadata.*.topics,
        };

        const topics = try topic_metadata.toArray(allocator);

        return .{ ._allocator = allocator, ._metadata = metadata, ._brokers = brokers, ._topics = topics };
    }

    pub fn deinit(self: Self) void {
        for (self._topics) |topic| self._allocator.free(topic.partitions);
        self._allocator.free(self._topics);
        self._allocator.free(self._brokers);
        librdkafka.rd_kafka_metadata_destroy(self._metadata);
    }

    pub inline fn listTopics(self: Self) []Topic {
        return self._topics;
    }

    pub fn describeTopic(self: Self, topic_name: []const u8) ?Topic {
        for (self._topics) |topic| {
            if (std.mem.eql(u8, topic_name, topic.name)) {
                return topic;
            }
        }
        return null;
    }

    pub inline fn listBrokers(self: Self) []Broker {
        return self._brokers;
    }

    pub fn describeBroker(self: Self, broker_host: []const u8) ?Broker {
        for (self._brokers) |broker| {
            if (std.mem.eql(u8, broker_host, broker.host)) {
                return broker;
            }
        }
        return null;
    }
};
