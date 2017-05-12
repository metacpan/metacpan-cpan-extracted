# This code is a part of tux_perl, and is released under the GPL.
# Copyright 2002 by Yale Huang<mailto:yale@sdf-eu.org>.
# See README and COPYING for more information, or see
#   http://tux-perl.sourceforge.net/.
#
# $Id: Makefile.PL,v 1.2 2002/11/11 11:17:02 yaleh Exp $

use ExtUtils::MakeMaker;
$Verbose = 1;
WriteMakefile(
	      NAME   => 'Tux',
	      SKIP   => [qw(static static_lib dynamic dynamic_lib)],
	      clean  => {'FILES' => 'tux_perl.$(DLEXT) tux_perl_imp.$(DLEXT)'},
	      INC    => '`perl -MExtUtils::Embed -e ccopts`',
	      DEFINE => '-DSYSCONFDIR=\"$(PREFIX)/etc\"',
	      MYEXTLIB => '$(INST_ARCHAUTODIR)/tux_perl.tux.$(DLEXT) $(INST_ARCHAUTODIR)/tux_perl_imp.$(DLEXT)',
);

sub MY::postamble {
'
$(INST_ARCHAUTODIR)/tux_perl.tux.$(DLEXT): tux_perl$(OBJ_EXT) config_hash$(OBJ_EXT)
'."\t".'$(LD) $(LDDLFLAGS) $^ -Wl,-soname -Wl,tux_perl.tux.$(DLEXT) -o $@

$(INST_ARCHAUTODIR)/tux_perl_imp.$(DLEXT): tux_perl_imp$(OBJ_EXT) config_hash$(OBJ_EXT) perlxsi$(OBJ_EXT)
'."\t".'$(LD) $(LDDLFLAGS) $^ `perl -MExtUtils::Embed -e ldopts`  -Wl,-soname -Wl,tux_perl_imp.$(DLEXT) -o $@

';

}
