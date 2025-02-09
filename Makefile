all: build
build:
	zig build

.PHONY: run
run:
	zig build run

.PHONY: test
test:
	zig test src/kafka.zig -lc -lrdkafka

.PHONY: style-fix
style-fix:
	zig fmt .

.PHONY: clean
clean:
	rm -rf zig-out

kafka-start:
	docker compose up -d

kafka-stop:
	docker compose stop
