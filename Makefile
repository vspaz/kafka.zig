all: build
build:
	zig build

.PHONY: run
run:
	zig build run

.PHONY: test
test:
	zig test src/main.zig

.PHONY: style-fix
style-fix:
	zig fmt .

.PHONY: clean
clean:
	rm -rf zig-out