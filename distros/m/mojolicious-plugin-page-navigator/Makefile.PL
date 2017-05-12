#!/usr/bin/env perl

use 5.008007;

use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'mojolicious-plugin-page-navigator',
    VERSION_FROM => 'lib/Mojolicious/Plugin/PageNavigator.pm',
    AUTHOR       => 'Silvio Quadri <silvioq@gmail.com>',
    PREREQ_PM => {
        'Mojolicious' => '1.41',
    },
    test => {TESTS => 't/*.t t/*/*.t t/*/*/*.t'}
);
