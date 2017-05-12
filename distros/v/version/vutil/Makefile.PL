#!/usr/bin/perl -w
use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'version::vxs',
    AUTHOR              => 'John Peacock <jpeacock@cpan.org>',
    VERSION_FROM        => 'lib/version/vxs.pm',
    depend              => { qw< vxs.c vxs.inc > },
);
