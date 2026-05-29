CC := gcc
CFLAGS := -O2 -Wall -Wextra -Wpedantic -fPIC -Iinclude
LDFLAGS := -shared
TARGET := libgreet.so

all: $(TARGET)

$(TARGET): src/greet.c include/greet.h
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ src/greet.c

clean:
	rm -f $(TARGET)

.PHONY: all clean
