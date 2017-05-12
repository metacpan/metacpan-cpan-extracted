#!perl -w
use strict;
#use warnings;

# Makefile.PL for Win32::GUI::DropFiles
# $Id: Makefile.PL,v 1.5 2008/02/01 13:29:49 robertemay Exp $

use 5.006;
use Config;
use ExtUtils::MakeMaker;

use lib '../build_tools';
use MMUtil;

my %config = (
    NAME          => 'Win32::GUI::DropFiles',
    VERSION_FROM  => 'DropFiles.pm',
    ABSTRACT_FROM => 'DropFiles.pm',
    AUTHOR        => 'Robert May <robertemay@users.sourceforge.net>',
    PREREQ_PM     => { 'Win32::GUI' => 1.04 },
    #DEFINE        => '-DW32G_NO_WIN9X',
    PL_FILES      => {'DropFilesRC.PL' => '$(BASEEXT).rc', },
    OBJECT        => '$(BASEEXT)$(OBJ_EXT) $(BASEEXT).res',
    macro         => { RC => 'rc.exe',
                       RCFLAGS => '',
                       INST_DEMODIR => '$(INST_LIB)/Win32/GUI/demos/$(BASEEXT)',
                       DEMOS => 'demos/DropFilesDemo.pl',
                     },
    clean         => {FILES => '*.rc *.res', },
);

# if building using gcc (MinGW or cygwin) use windres
# as the resource compiler
if($Config{cc} =~ /gcc/i) {
    $config{macro}->{RC} =      'windres';
    $config{macro}->{RCFLAGS} = '-O coff -o $*.res';
    $config{CCFLAGS} = "$Config{ccflags} -Wno-write-strings";
}

# if building as part of the Win32::GUI core, then remove
# the pre-req of Win32::GUI, as we may not have it until
# we finish the build.
{ no warnings 'once';
delete $config{PREREQ_PM}->{'Win32::GUI'} if $main::W32G_CORE; }

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
sub postamble {
  return <<'__POSTAMBLE';

.rc.res:
	$(RC) $(RCFLAGS) $<

pure_all :: demo_to_blib
	$(NOECHO) $(NOOP)

demo_to_blib: $(DEMOS)
	$(NOECHO) $(MKPATH) $(INST_DEMODIR)
	$(CP) $? $(INST_DEMODIR)
	$(NOECHO) $(TOUCH) demo_to_blib

clean ::
	-$(RM_F) demo_to_blib

__POSTAMBLE
}
