const std = @import("std");

pub const ConfigBuilder = @import("config.zig").Builder;
pub const Consumer = @import("consumer.zig").Consumer;
pub const Message = @import("message.zig").Message;
const producer = @import("producer.zig");
pub const Producer = producer.Producer;
pub const setCb = producer.setCb;
pub const TopicBuilder = @import("topic.zig").Builder;
pub const metadata = @import("metadata.zig");

test {
    std.testing.refAllDecls(@This());
}

pub fn main() !void {}
