# Developer Makefile to build test files

ifeq ($(OS),Windows_NT)
  EXESUFFIX	:= .exe
else
  EXESUFFIX ?=
endif

BAS = $(wildcard t2p/input/*.bas)
P = $(patsubst t2p/input/%.bas,t2p/expected/%.p, $(BAS))

all: zxtext2p/zxtext2p$(EXESUFFIX)

zxtext2p/zxtext2p$(EXESUFFIX): zxtext2p/zxtext2p.c
	$(CC) -o $@ $<

t2p/expected/%.p: t2p/input/%.bas zxtext2p/zxtext2p$(EXESUFFIX) Makefile t2p.pl
	perl t2p.pl -o $@ $<
#	zxtext2p/zxtext2p$(EXESUFFIX) -o $@ $<

all: $(P)
