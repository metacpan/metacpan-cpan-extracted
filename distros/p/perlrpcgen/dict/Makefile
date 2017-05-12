# $Id: Makefile,v 1.4 1997/04/30 21:06:44 jake Exp $

#   Copyright 1997 Jake Donham <jake@organic.com>

#   You may distribute under the terms of either the GNU General
#   Public License or the Artistic License, as specified in the README
#   file.

INT=dict
MOD=Dict
CC=gcc
PERL=/home/jake/debugperl/bin/perl
PERLRPCGEN=perlrpcgen
RPCLIBS=-lrpcsvc -lnsl
CFLAGS=-g

all: .perlmods $(MOD)/server/$(INT)_svc

.perlrpcgen: $(INT).x
	$(PERLRPCGEN) -perl $(PERL) -all -module Dict -typemap \
	`$(PERL) -MConfig -e 'print "$$Config{privlib}/ExtUtils/typemap"'` \
	$(INT).x
	mkdir -p $(MOD)/lib/Tie
	cd $(MOD)/lib/Tie; ln -s ../../../Dict.pm
	touch .perlrpcgen

.Makefiles: .perlrpcgen
	cd $(MOD); $(PERL) Makefile.PL
	touch .Makefiles

$(INT)_xdr.c $(INT)_clnt.c $(INT)_svc.c: $(INT).x
	rpcgen $(INT).x
	mv $(INT)_svc.c $(INT)_svc.c~
	sed -e "s/svc_run();/initperl(argc, argv); svc_run();/" \
	    -e "s/main()/main(int argc, char **argv)/" \
	    -e "s/for (i = 0;/\/*for (i=0;/" \
	    -e "s/(i, 2);/(i, 2);\*\//" \
	    < $(INT)_svc.c~ > $(INT)_svc.c

.perlmods: .Makefiles $(INT)_xdr.o $(INT)_clnt.o
	cd $(MOD); make
	touch .perlmods

$(MOD)/server/$(INT)_svc: .perlrpcgen $(INT)_svc.o
	cd $(MOD)/server; make $(INT)_svc

tidy:
	rm -f *~ "#*" core

clean: tidy
	rm -f .perlrpcgen .Makefiles .perlmods
	rm -f *.h *.c *.o
	rm -rf $(MOD)

install: all
	cd $(MOD); make install
