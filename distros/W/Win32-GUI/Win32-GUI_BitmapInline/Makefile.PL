#!perl -w
use strict;
#use warnings;

# Makefile.PL for Win32::GUI::BitmapInline
# $Id: Makefile.PL,v 1.1 2008/01/13 11:42:57 robertemay Exp $

use 5.006;
use ExtUtils::MakeMaker;
use Config;

my %config = (
    NAME          =>  'Win32::GUI::BitmapInline',
    VERSION_FROM  =>  'BitmapInline.pm',
    ABSTRACT_FROM =>  'BitmapInline.pm',
    AUTHOR        =>  'Robert May <robertemay@users.sourceforge.net>',
);

# if building using gcc (MinGW or cygwin)
if($Config{cc} =~ /gcc/i) {
    $config{CCFLAGS} = "$Config{ccflags} -Wno-write-strings";
}

WriteMakefile(%config);
