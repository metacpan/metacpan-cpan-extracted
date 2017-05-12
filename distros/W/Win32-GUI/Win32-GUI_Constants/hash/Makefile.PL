#!perl -w
use strict;
use warnings;

# Makefile.PL for perfect.exe
# Writes a makefile that supports enough targets to play
# nicely with ExtUtils::MakeMaker.
# $Id: Makefile.PL,v 1.2 2006/06/11 21:00:15 robertemay Exp $

use 5.006;
use Config;

print "Writing Makefile for Win32::GUI::Constants - perfect.exe\n";

my $file = 'Makefile';

open my $fh, '>', $file or die "Failed to open $file for writing: $!";
my $oldfh = select $fh;

# Generic configuration
my $nologo = "";
my $output = '-o $@';
my $cflags = "-O";
my $ldflags = $Config{libs} =~ /(bufferoverflow.*?\.lib)/ ? $1 : '';

if($Config{cc} =~ /gcc/) {  # gcc, e.g. MinGW
    $cflags .= " -fno-builtin-log2";
}
elsif($Config{cc} =~ /cl/) {  # MSVC
    $nologo = "-nologo";
    $output = "-Fe\$@";
}

print <<MAKEFILE;
#Makefile for Win32::GUI::Constants helper
#perfect.exe

PERL=$Config{perlpath}
RM_RF= \$(PERL) -MExtUtils::Command -e rm_rf
CC=$Config{cc}
CFLAGS=$cflags
LDFLAGS=$ldflags
NOLOGO=$nologo
OBJECT= lookupa$Config{obj_ext} recycle$Config{obj_ext} perfhex$Config{obj_ext} perfect$Config{obj_ext}

all: perfect.exe

perfect.exe: \$(OBJECT)
	\$(CC) \$(NOLOGO) \$(LDFLAGS) $output \$(OBJECT)

.c$Config{obj_ext}:
	\$(CC) \$(NOLOGO) \$(CFLAGS) -c \$<

# CLEAN
clean:
	\$(RM_RF) perfect.exe \$(OBJECT)

realclean: clean
	\$(RM_RF) $file

veryclean: realclean

#Test - will be call by parent Makefiles
test:
test_dynamic:

# DEPENDENCIES

lookupa.$Config{obj_ext} : lookupa.c standard.h lookupa.h

recycle.$Config{obj_ext} : recycle.c standard.h recycle.h

perfhex.$Config{obj_ext} : perfhex.c standard.h lookupa.h recycle.h perfect.h

perfect.$Config{obj_ext} : perfect.c standard.h lookupa.h recycle.h perfect.h

MAKEFILE

select $oldfh;
close $fh;
