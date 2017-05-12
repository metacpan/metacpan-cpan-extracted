# Copyright 2000-2004, Phill Wolf.  See README.

# Win32::ActAcc (Active Accessibility)

use ExtUtils::MakeMaker;
use Data::Dumper;
use File::Find;

require 5.8.0; # maybe works with something older

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
my %h = (
    'NAME'		=> 'Win32::ActAcc',
    'VERSION_FROM'	=> 'ActAcc.pm', # finds $VERSION
    'PREREQ_PM'		=> {'Win32::OLE'=>0.13, 'Text::Trie'=>undef, 'IO::Tee'=>0.64},
    'LIBS'		=> [':nosearch OleAcc.lib'],
    'DEFINE'		=> '-D_WIN32_WINNT=0x0501', 
    'INC'		=> '', # e.g., '-I/usr/include/other',
	'EXE_FILES' => ['aadigger.pl','aaEvents.pl','aaWhereAmI.pl'],
	'MYEXTLIB'=>'ActAccEL.lib',
	'AUTHOR' => 'Phill Wolf (pbwolf@cpan.org)',
	'depend' => +{'ActAcc.c'=>'ActAcc.xsh AO.xsh EM.xsh', 'ActAcc.xs'=>'consts.xsh'},
	'clean' => +{'FILES'=>'ActAccEM.dll ActAccEM.obj ActAccEM.exp x86/Win32-ActAcc.tar.gz'},
);

#debugging
if (0)
{
	$h{'OPTIMIZE'} = "/Od /GZ /FdActAcc.pdb /Zi /D_DEBUG";
}


WriteMakefile(%h);

sub MY::postamble
{  
	my $rv = "";
	my @a = <DATA>;
	return $rv . join('',@a);   
}


__END__

dynamic :: $(INST_ARCHAUTODIR)\ActAccEM.dll
	rem

# -Od = disable optimizations
# -W4 = set warning level 4
# -MT = link with LIBCMT.LIB (multi-threaded)
# -TP = compile all files as C++
ActAccEM_CCFLAGS = -TP -MT -W4 -Od -DNDEBUG -DWIN32

ActAccEL.obj: ActAccEL.x AAEvtMon.h
	$(CC) -c $(ActAccEM_CCFLAGS) ActAccEL.x

# ActAccEL static library is required by the main extension and by ActAccEM.dll.
# (It must be a library because its cc flags differ from the cc flags used by the main extension.)
ActAccEL.lib: ActAccEL.obj
	$(AR) /name:ActAccEL.lib ActAccEL.obj

ActAccEM.obj: ActAccEM.x AAEvtMon.h ActAccEL.lib
	$(CC) -c $(ActAccEM_CCFLAGS) ActAccEM.x

ActAccEM_LDDLFLAGS = -dll -nologo -machine:x86

$(INST_ARCHAUTODIR)\ActAccEM.dll ActAccEM.lib: ActAccEM.obj
	$(LD) -out:$(INST_ARCHAUTODIR)\ActAccEM.dll -implib:ActAccEM.lib $(ActAccEM_LDDLFLAGS) ActAccEL.lib ActAccEM.obj kernel32.lib 


