#!/usr/bin/env perl

use 5.008001;

use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'WebService::PutIo',
    VERSION_FROM => 'lib/WebService/PutIo.pm',
    AUTHOR       => 'Marcus Ramberg <mramberg@cpan.org>',
    PREREQ_PM    => {'Mojolicious' => '2.0'},
    test => {TESTS => 't/*.t t/*/*.t t/*/*/*.t'}
);
