# -----------------------------------------------------------------------------
# Makefile for unijp.erl.
# -----------------------------------------------------------------------------
# Mastering programmed by YAMASHINA Hio
#
# Copyright 2007 YAMASHINA Hio
# -----------------------------------------------------------------------------
# $Id: Makefile 219 2008-02-01 08:21:48Z hio $
# -----------------------------------------------------------------------------

DISTNAME=unijp
VERSION=0.4.0.2
DISTVERNAME=$(DISTNAME)-$(VERSION)

PERLRUN=perl

WITH_LIBUNIJP=/usr/local
DESTDIR=

ERL=erl
ERLC=erlc
ERL_DIR=$(shell $(ERL) -noshell -eval 'io:format("~s~n", [code:root_dir()]), init:stop().')
ERL_LIB_DIR=$(shell $(ERL) -noshell -eval 'io:format("~s~n", [code:lib_dir()]), init:stop().')
INST_DIR=$(DESTDIR)$(ERL_LIB_DIR)/$(DISTVERNAME)
ERLEVAL=$(ERL) -noshell -pa $(bdir) -run unijp start -eval
ERL_INTERFACE_DIR=$(shell $(ERL) -noshell -eval 'io:format("~s~n", [code:lib_dir(erl_interface)]), init:stop()')

OPTIMIZE=-g -O2
CFLAGS= \
  -Wall $(OPTIMIZE) \
  -I$(ERL_DIR)/usr/include \
  -I$(ERL_INTERFACE_DIR)/include \
  -I$(WITH_LIBUNIJP)/include 
LDFLAGS=\
  -L$(ERL_INTERFACE_DIR)/lib \
  -L$(WITH_LIBUNIJP)/lib
LDLIBS=-lerl_interface -lei -lunijp

DLLD_Linux=gcc -shared -fPIC
DLLD_Darwin=cc -bundle -undefined dynamic_lookup -fPIC 
DLLD=$(DLLD_$(shell uname -s))

bdir=build/$(DISTVERNAME)

nil=
BUILD_FILES=\
	$(bdir)/src/unijp.erl \
	$(bdir)/ebin/unijp.beam \
	$(bdir)/ebin/unijp_nif.beam \
	$(bdir)/priv/lib/unijp_nif.so \
	$(nil)

# -----------------------------------------------------------------------------
# all, clean, test, install, docs.
#
all: $(BUILD_FILES)

install: all
	echo "[$(ERL_LIB_DIR)]"
	test -e $(INST_DIR) || mkdir -p $(INST_DIR)
	cp -r $(bdir)/ebin $(bdir)/priv $(bdir)/src $(INST_DIR)/

clean:
	rm -rf *.so *.o unijp.beam unijp_nif.beam ebin priv build

docs:
	$(ERL) -noshell -run edoc_run files '["unijp.erl", "inc/test_more.erl"]' '[{dir,"html"}]'

test_lib: inc/test_more.beam inc/test_harness.beam
inc/test_more.beam: inc/test_more.erl; $(ERLC) -o $(@D) inc/test_more.erl
inc/test_harness.beam: inc/test_harness.erl; $(ERLC) -o $(@D) inc/test_harness.erl

test: check
check: all
	$(ERLC) test1.erl
	$(ERL) -noshell -pa $(bdir) -pa inc -pa t -run test1 test -run init stop

# -----------------------------------------------------------------------------
# build rules.
#

$(bdir):
	test -e build || mkdir build
	test -e $(bdir) || mkdir $(bdir)

# bdir/unijp
$(bdir)/src/unijp.erl: $(bdir) unijp.erl
	test -e $(bdir)/src || mkdir $(bdir)/src
	cp -f unijp.erl $(bdir)/src/unijp.erl
$(bdir)/ebin/unijp.beam: $(bdir) unijp.beam
	test -e $(bdir)/ebin || mkdir $(bdir)/ebin
	cp -f unijp.beam $(bdir)/ebin/unijp.beam
$(bdir)/ebin/unijp_nif.beam: $(bdir) unijp_nif.beam
	test -e $(bdir)/ebin || mkdir $(bdir)/ebin
	cp -f unijp_nif.beam $(bdir)/ebin/unijp_nif.beam
$(bdir)/priv/lib/unijp_nif.so: $(bdir) unijp_nif.so
	test -e $(bdir)/priv     || mkdir $(bdir)/priv
	test -e $(bdir)/priv/lib || mkdir $(bdir)/priv/lib
	cp -f unijp_nif.so $(bdir)/priv/lib/unijp_nif.so

# unijp.erl
unijp.beam: unijp.erl
	$(ERLC) +debug_info $<
unijp_nif.beam: unijp_nif.erl
	$(ERLC) +debug_info $<
unijp_nif.so: unijp_nif.c
	$(DLLD) $(CFLAGS) $(LDFLAGS) $< -o $@ $(LDLIBS)

shell:
	UNIJP_INPLACE_NIF_MODULE_DIR=$(bdir)/priv/lib \
		$(ERL) -pa $(bdir)

# -----------------------------------------------------------------------------
# dist.
#
dist:
	rm -rf $(DISTVERNAME) $(DISTVERNAME).tar $(DISTVERNAME).tar.gz
	$(PERLRUN) -MExtUtils::Manifest=manicopy,maniread -e 'manicopy(maniread(), "$(DISTVERNAME)")'
	tar cvf $(DISTVERNAME).tar $(DISTVERNAME)
	gzip --best $(DISTVERNAME).tar
	rm -rf $(DISTVERNAME)

# -----------------------------------------------------------------------------
# End of File.
# -----------------------------------------------------------------------------
