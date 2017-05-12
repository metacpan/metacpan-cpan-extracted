#!perl -w
use strict;
#use warnings;

# Makefile.PL for Win32::GUI::ReleaseNotes
# $Id: Makefile.PL,v 1.1 2006/07/16 11:09:33 robertemay Exp $

use 5.006;
use ExtUtils::MakeMaker;
use File::Find();

my $pm_files = {
    'ReleaseNotes.pod' => '$(INST_LIBDIR)/ReleaseNotes.pod',
};

File::Find::find(sub { $pm_files->{$_} = "\$(INST_LIBDIR)/ReleaseNotes/$_" if /^RN.*\.pod/; }, '.');

my %config = (
    NAME          =>  'Win32::GUI::ReleaseNotes',
    VERSION       =>  1.0,
    ABSTRACT_FROM =>  'ReleaseNotes.pod',
    AUTHOR        =>  'Robert May <robertemay@users.sourceforge.net>',
    PM            =>  $pm_files,
);

WriteMakefile(%config);
