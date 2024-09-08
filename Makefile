CC := clang
FRAMEWORKS := Cocoa Metal MetalKit QuartzCore
FRAMEWORKFLAGS := $(patsubst %,-framework %,$(FRAMEWORKS))
CFLAGS := -c -MMD -MP -Werror -Wall -fobjc-arc
LD := clang
LDFLAGS := $(FRAMEWORKFLAGS)

BUILDDIR := ./build

SRCS := $(wildcard *.m)
OBJS := $(patsubst %.m,$(BUILDDIR)/%.o,$(SRCS))
DEPS := $(patsubst %.o,%.d,$(OBJS))

BIN := $(BUILDDIR)/MyApp

.PHONY: all clean

all: $(BIN)

$(BIN): $(OBJS)
	$(LD) $(LDFLAGS) -o $@ $^

$(BUILDDIR)/%.o: %.m
	@mkdir -p $(BUILDDIR)
	$(CC) $(CFLAGS) -o $@ $<

clean:
	rm -rf $(BUILDDIR)

-include $(DEPS)
