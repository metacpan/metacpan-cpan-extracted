#! /usr/bin/perl
use 5.010;
use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile
    NAME          => 'fixedtime',
    VERSION_FROM  => 'lib/fixedtime.pm',
    ABSTRACT_FROM => 'lib/fixedtime.pm',
;
