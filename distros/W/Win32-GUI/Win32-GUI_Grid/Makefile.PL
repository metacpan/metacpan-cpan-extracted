#!perl -w
use strict;
#use warnings;

# Makefile.PL for Win32::GUI::Grid
# $Id: Makefile.PL,v 1.5 2008/02/01 13:29:49 robertemay Exp $

use 5.006;
use Config;
use ExtUtils::MakeMaker;
use File::Find();

use lib '../build_tools';

my @demos;
File::Find::find(sub { push @demos, $File::Find::name if $File::Find::name =~ /\.(pl|bmp)$/ }, 'demos');

my %config = (
    NAME          =>  'Win32::GUI::Grid',
    VERSION_FROM  =>  'Grid.pm',
    ABSTRACT_FROM =>  'Grid.pm',
    AUTHOR        =>  'ROCHER Laurent (lrocher@cpan.org)',
    XS            => { 'Grid.xs' => 'Grid.cpp' },
    LIBS          => ['-lcomctl32 -lMfc42 -lEafxis'],
    MYEXTLIB      =>  './MFCGrid/Lib/MFCGrid.lib',
    PL_FILES      => {'GridRC.PL' => '$(BASEEXT).rc', },
    OBJECT        =>  '$(BASEEXT)$(OBJ_EXT) $(BASEEXT).res',
    macro         => {RC => 'rc.exe',
                      RCFLAGS => '',
                      INST_DEMODIR => '$(INST_LIB)/Win32/GUI/demos/$(BASEEXT)',
                      DEMOS => "@demos", },
    clean         => {FILES => '*.rc *.res MFCGrid/Build/* MFCGrid/Lib/* ', },
);

# if building using gcc (MinGW or cygwin) use windres
# as the resource compiler
# and the MinGW C++ standard library
if($Config{cc} =~ /gcc/i) {
    $config{macro}->{RC} =      'windres';
    $config{macro}->{RCFLAGS} = '-O coff -o $*.res';
    $config{LIBS} = [':nodefault -lcomctl32 -lmsvcp60'];
    $config{CCFLAGS} = "$Config{ccflags} -Wno-write-strings";
}

# Can only build with mscv.
if($ENV{SKIP_WIN32_GUI_GRID}) {
    print <<__EXPLAIN;

Win32::GUI::Grid skipped

__EXPLAIN
    ExtUtils::MakeMaker::WriteEmptyMakefile(NAME => 'Win32::GUI::Grid');
}
elsif($Config{cc} !~ /cl/i) {
    print <<__EXPLAIN;

Win32::GUI::Grid can only be built using MSVC, not '$Config{cc}',
as it requires the MFC framework.
Win32::GUI::Grid will be skipped during the current build process.

__EXPLAIN
    ExtUtils::MakeMaker::WriteEmptyMakefile(NAME => 'Win32::GUI::Grid');
}
else {
    MMUtil::Extend_MM();
    WriteMakefile(%config);
}

package MY;

sub special_targets {
    my $inherited = shift->SUPER::special_targets(@_);
    $inherited =~ s/^(.SUFFIXES.*)$/$1 .rc .res/m;
    return $inherited;
}

sub xs_c {
  my $inherited = shift->SUPER::xs_c(@_);
  $inherited =~ s/\.c/.cpp/g;
  return $inherited;
}

# Add rule to make MFCGrid.lib
# Add rule for .rc to .res conversion
# Add rules to install demo scripts
sub postamble {
  return <<'__POSTAMBLE';

# Win32::GUI::Grid MFCGrid.lib section

./MFCGrid/Lib/MFCGrid.lib: MFCGrid/makefile.mfcgrid
	cd MFCGrid
	$(MAKE) -f Makefile.mfcgrid $(PASTHRU)
	cd ..

# Win32::GUI::Grid RC section

.rc.res:
	$(RC) $(RCFLAGS) $<

# Win32::GUI::Grid demo script section

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
