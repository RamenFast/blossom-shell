#==========================================
#  Makefile: Blossom-themed sl
#  Builds the colourised train from blossom-sl.c + sl.h.
#  `make install` drops it at ~/.local/bin/sl so it shadows /usr/games/sl.
#==========================================

CC      ?= gcc
CFLAGS  ?= -O -Wall
PREFIX  ?= $(HOME)/.local
BINDIR   = $(PREFIX)/bin

all: sl

sl: blossom-sl.c sl.h
	$(CC) $(CFLAGS) -o sl blossom-sl.c -lncurses

install: sl
	mkdir -p $(BINDIR)
	install -m 755 sl $(BINDIR)/sl
	@echo "installed: $(BINDIR)/sl  (type 'sl' to ride)"

uninstall:
	rm -f $(BINDIR)/sl

clean:
	rm -f sl

.PHONY: all install uninstall clean
