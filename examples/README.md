### Kafka.zig
running examples

1. Install C/C++ librdkafka as described [here](https://github.com/vspaz/kafka.zig?tab=readme-ov-file#dependencies) unless you have already done so.

2. Clone repository
```shell
git clone git@github.com:vspaz/kafka.zig.git
```
3. Start a test kafka instance
```shell
cd kafka.zig
make kafka-start  # it takes a few seconds
```
4. Run examples
```shell
cd examples
zig build run
```
