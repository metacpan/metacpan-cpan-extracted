#!perl -w
use strict;
#use warnings;

# Makefile.PL for Win32::GUI::Scintilla
# $Id: Makefile.PL,v 1.4 2008/02/01 13:29:49 robertemay Exp $

use 5.006;
use Config;
use ExtUtils::MakeMaker;
use File::Find();

use lib '../build_tools';
use MMUtil();

my @demos;
File::Find::find(sub { push @demos, $File::Find::name if $File::Find::name =~ /\.pl$/ }, 'demos');

my $sc = ($Config{archname} =~ /x64/ || $Config{myuname} =~ /x86_64/) ? 'SciLexer64.dll' : 'SciLexer32.dll';

my %config = (
    NAME          =>  'Win32::GUI::Scintilla',
    VERSION_FROM  =>  'Scintilla.PL',
    ABSTRACT_FROM =>  'Scintilla.pod',
    AUTHOR        =>  'ROCHER Laurent (lrocher@cpan.org)',
    PM            => {'Scintilla.pod'        => '$(INST_LIBDIR)/Scintilla.pod',
                      'Perl.pm'              => '$(INST_LIBDIR)/Scintilla/Perl.pm',
                      "Include/$sc"          => '$(INST_ARCHAUTODIR)/SciLexer.dll', },
    PL_FILES      => {'Scintilla.PL'   => '$(INST_LIBDIR)/Scintilla.pm',
                      'ScintillaRC.PL' => '$(BASEEXT).rc', },
    OBJECT        =>  '$(BASEEXT)$(OBJ_EXT) $(BASEEXT).res',
    macro         => {RC => 'rc.exe',
                      RCFLAGS => '',
                      INST_DEMODIR => '$(INST_LIB)/Win32/GUI/demos/$(BASEEXT)',
                      DEMOS => "@demos", },
    depend        => {'Scintilla.pm' => 'Include/Scintilla.iface', },
    clean         => {FILES => '*.rc *.res', },
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
sub postamble {
  return <<'__POSTAMBLE';

# Win32::GUI::Scintilla RC section

.rc.res:
	$(RC) $(RCFLAGS) $<

# Win32::GUI::Scintilla demo script section

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
