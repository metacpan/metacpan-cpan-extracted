# Developer Makefile to build test files

ifeq ($(OS),Windows_NT)
  EXESUFFIX	:= .exe
else
  EXESUFFIX ?=
endif

BAS = $(wildcard input/*.bas)
P = $(patsubst input/%.bas,expected/%.p, $(BAS))

all: zxtext2p/zxtext2p$(EXESUFFIX)

zxtext2p/zxtext2p$(EXESUFFIX): zxtext2p/zxtext2p.c
	$(CC) -o $@ $<

expected/%.p: input/%.bas zxtext2p/zxtext2p$(EXESUFFIX) Makefile t2p.pl
	perl t2p.pl -o $@ $<
#	zxtext2p/zxtext2p$(EXESUFFIX) -o $@ $<

all: $(P)
