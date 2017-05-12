#!perl

use 5.009005;
use strict;
use ExtUtils::MakeMaker;

if (ord("A") == 193) {
    die "This module does not support EBCDIC platforms.\n";
}

WriteMakefile(
    AUTHOR	    => 'Rafael Garcia-Suarez <rgs@consttype.org>',
    NAME	    => 'encoding::source',
    VERSION_FROM    => 'lib/encoding/source.pm',
    PREREQ_PM	    => { Encode => 0 },
    LICENSE	    => 'perl',
    ABSTRACT        => "Allows you to write your script in non-ascii or non-utf8",
);
