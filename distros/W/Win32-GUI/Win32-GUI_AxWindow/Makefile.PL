#!perl -w
use strict;
#use warnings;

# Makefile.PL for Win32::GUI::AxWindow
# $Id: Makefile.PL,v 1.4 2008/02/01 13:29:49 robertemay Exp $

use 5.006;
use Config;
use ExtUtils::MakeMaker;
use File::Find();

use lib '../build_tools';
use MMUtil;

my @demos;
File::Find::find(sub { push @demos, $File::Find::name if $File::Find::name =~ /\.(pl|pm|avi)$/ }, 'demos');

my %config = (
    NAME          =>  'Win32::GUI::AxWindow',
    VERSION_FROM  =>  'AxWindow.pm',
    ABSTRACT_FROM =>  'AxWindow.pm',
    AUTHOR        =>  'ROCHER Laurent (lrocher@cpan.org)',
    PL_FILES      => {'AxWindowRC.PL' => '$(BASEEXT).rc', },
    XS            => {'AxWindow.xs' => 'AxWindow.cpp' },
    OBJECT        =>  '$(BASEEXT)$(OBJ_EXT) $(BASEEXT).res',
    LIBS          => ['-latl'],
    macro         => {RC => 'rc.exe',
                      RCFLAGS => '',
                      INST_DEMODIR => '$(INST_LIB)/Win32/GUI/demos/$(BASEEXT)',
                      DEMOS => "@demos", },
    clean         => {FILES => '*.rc *.res', },
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

if($Config{cc} =~ /cl/i) {
    # workaround for: cannot convert from 'INT_PTR (__stdcall *)(HWND,UINT,WPARAM,LPARAM)' to 'DLGPROC'
    # http://sourceforge.net/p/perl-win32-gui/mailman/message/2618474/
    $config{CCFLAGS} = "$Config{ccflags} -UNO_STRICT";
}

if($ENV{SKIP_WIN32_GUI_AXWINDOW}) {
    print <<__EXPLAIN;

Win32::GUI::AxWindow skipped

__EXPLAIN
    ExtUtils::MakeMaker::WriteEmptyMakefile(NAME => 'Win32::GUI::AxWindow');
}
elsif($Config{cc} !~ /cl/i || $Config{archname} =~ /x64/) {
    print <<__EXPLAIN;

Win32::GUI::AxWindow can only be built using MSVC (currently 32bit only)',
as it depends on the Microsoft Active Template Library (ATL).
Win32::GUI::AxWindow will be skipped during the current build process.

__EXPLAIN
    ExtUtils::MakeMaker::WriteEmptyMakefile(NAME => 'Win32::GUI::AxWindow');
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

# Add rule for .rc to .res conversion
# Add rules to install demo scripts
sub postamble {
  return <<'__POSTAMBLE';

# Win32::GUI::DIBitmap RC section

.rc.res:
	$(RC) $(RCFLAGS) $<

# Win32::GUI::DIBitmap demo script section

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
