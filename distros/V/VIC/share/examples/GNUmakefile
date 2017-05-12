#######################################
### COPYRIGHT: Selective Intellect LLC
### AUTHOR: Vikas Kumar
### DATE: 29th May 2013
### SOFTWARE: PIC uC Software
#######################################
#GPASM?=$(shell which gpasm)
#GPLINK?=$(shell which gplink)
PK2CMD?=$(shell which pk2cmd)
PIC?=
VIC?=$(shell which vic)
CURDIR:=$(shell pwd)

ifeq ($(VIC),)
$(error "Unable to find the 'vic' program for compiling. Please set it in the $$PATH")
endif

ifneq ($(PIC),)
 PICOPT:=--pic $(PIC)
else
 PICOPT:=
endif
ifeq ($(VERBOSE),1)
 QUIET:=
 VICOPT:=-i $(PICOPT) --verbose
else
 QUIET:=-q
 VICOPT:=$(PICOPT)
endif

ASMFILES:=$(patsubst %.vic,%.asm,$(wildcard *.vic))
HEXFILES:=$(patsubst %.vic,%.hex,$(wildcard *.vic))
TARGETS:=$(patsubst %.vic,%,$(wildcard *.vic))
SIMFILES:=$(patsubst %.vic,%.stc,$(wildcard *.vic))

default: all
.PHONY: default

all: $(HEXFILES) $(ASMFILES) $(SIMFILES)
.PHONY: all

rebuild: clean all
.PHONY: rebuild

clean:
	rm -f $(HEXFILES)
	rm -f $(ASMFILES)
	rm -f $(SIMFILES)
	rm -f *.map *.lst *.cod *.o *.d
.PHONY: clean

test:
	@echo "Starting test"
	$(PK2CMD) -P$(PIC) -T
.PHONY: test

stoptest:
	@echo "Stopping test"
	$(PK2CMD) -P$(PIC)
.PHONY: stoptest

erase:
	@echo "Erasing $(PIC)"
	$(PK2CMD) -P$(PIC) -E
.PHONY: erase

# using a static pattern to automatically create a dependency on corresponding
# hex file
$(TARGETS): %: %.hex
	@echo "Programming $@ with $<"
	$(PK2CMD) -P$(PIC) -M -F$<
.PHONY: $(TARGETS)

#%.hex: %.o
#	$(GPLINK) $(QUIET) -m -o $@ $<

#%.stc: %.cod
#	@echo "load s $*.cod" | tee $*.stc

#%.o %.cod: %.asm
#	$(GPASM) -p$(PIC) -M -c $<

#%.asm: %.vic
#	$(VIC) $(VICOPT) -o $@ $<

%.hex: %.vic
	$(VIC) $(VICOPT) -o $@ $<

%.asm: %.vic
	$(VIC) --no-hex $(VICOPT) -o $@ $<

%.sim: %.vic
	$(VIC) --simulate $(VICOPT) -o $*.hex $<

-include $(HEXFILES:.hex=.d)
