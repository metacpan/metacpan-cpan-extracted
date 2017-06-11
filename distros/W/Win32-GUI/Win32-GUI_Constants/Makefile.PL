#!perl -w
use strict;
#use warnings;

# Makefile.PL for Win32::GUI::Constants
# $Id: Makefile.PL,v 1.3 2008/02/01 13:29:49 robertemay Exp $

use 5.006;
use Config;
use ExtUtils::MakeMaker;

use lib '../build_tools';
use MMUtil;

my %config = (
    NAME          =>  'Win32::GUI::Constants',
    VERSION_FROM  =>  'Constants.pm',
    ABSTRACT_FROM =>  'Constants.pm',
    AUTHOR        =>  'Robert May <robertemay@users.sourceforge.net>',
    PM            => {'Constants.pm' => '$(INST_LIBDIR)/Constants.pm',
                      'Tags.pm'      => '$(INST_LIBDIR)/$(BASEEXT)/Tags.pm', },
    PL_FILES      => {'ConstantsRC.PL' => '$(BASEEXT).rc',
                      'Constants.PL'   => [ 'constants.src', 'constants.h', 't/70_values.def', 'phash.inc'], },
    OBJECT        =>  '$(BASEEXT)$(OBJ_EXT) $(BASEEXT).res',
    macro         => {RC => 'rc.exe',
                      RCFLAGS => '',
                      INST_DEMODIR => '$(INST_LIB)/Win32/GUI/demos/$(BASEEXT)',
                      DEMOS => 'demos/ConstantsDemo.pl' },
    clean         => {FILES => '*.rc *.res constants.src constants.h t/70_values.def phash.inc phash.def', },
    depend        => {'Constants.c' => 'constants.h phash.def phash.inc', },
    ##### depend        => {'Constants.o' => 'Constants.c constants.h phash.inc',
    #####                   ##'phash.inc' => 'phash.def',
    #####                   ##'phash.def' => 'constants.src'
    #####                  },
);

# if building using gcc (MinGW or cygwin) use windres
# as the resource compiler
if($Config{cc} =~ /gcc/i) {
    $config{macro}->{RC} =      'windres';
    $config{macro}->{RCFLAGS} = '-O coff -o $*.res';
    $config{CCFLAGS} = "$Config{ccflags} -Wno-write-strings";
}

MMUtil::Extend_MM();
WriteMakefile(%config);

package MY;

sub special_targets {
    my $inherited = shift->SUPER::special_targets(@_);
    $inherited =~ s/^(.SUFFIXES.*)$/$1 .rc .res/m;
    return $inherited;
}

# Add rule for .rc to .res conversion
# Add rules to install demo scripts
# Add rules to make the perfect hash code (phash.inc)
sub postamble {
  return sprintf <<'__POSTAMBLE', ($^O eq 'cygwin' ? 'hash/perfect.exe' : 'hash\perfect.exe');

# Win32::GUI::Constansts RC section

.rc.res:
	$(RC) $(RCFLAGS) $<

# Win32::GUI::Constansts demo script section

pure_all :: demo_to_blib
	$(NOECHO) $(NOOP)

demo_to_blib: $(DEMOS)
	$(NOECHO) $(MKPATH) $(INST_DEMODIR)
	$(CP) $? $(INST_DEMODIR)
	$(NOECHO) $(TOUCH) demo_to_blib

clean ::
	-$(RM_F) demo_to_blib

# Win32::GUI::Constansts perfect hash section

phash.def :: subdirs

phash.def :: constants.src
	%s < constants.src

__POSTAMBLE
}
