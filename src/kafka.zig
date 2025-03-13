const std = @import("std");

const cb = @import("callbacks.zig");
pub const ConfigBuilder = @import("config.zig").Builder;
pub const Consumer = @import("consumer.zig").Consumer;
pub const Message = @import("message.zig").Message;
const Producer = @import("producer.zig").Producer;
pub const TopicBuilder = @import("topic.zig").Builder;
pub const metadata = @import("metadata.zig");
pub const AdminApiClient = @import("admin.zig").ApiClient;

pub const setCb = cb.setCb;
pub const setErrCb = cb.setErrCb;
pub const setConsumeCb = cb.setConsumeCb;

test {
    std.testing.refAllDecls(@This());
}

pub fn main() !void {}
