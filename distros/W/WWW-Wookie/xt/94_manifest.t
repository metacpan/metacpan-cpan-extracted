# -*- cperl; cperl-indent-level: 4 -*-
## no critic (RequireExplicitPackage RequireEndWithOne)
use 5.020;
use strict;
use warnings;
use utf8;

use Test::More 'tests' => 2;

our $VERSION = v1.1.5;

eval {
    require ExtUtils::Manifest;
    1;
} or do {
    my $msg = q{ExtUtils::Manifest required to check manifest};
    Test::More::plan 'skip_all' => $msg;
};

use ExtUtils::Manifest;
Test::More::is_deeply [ ExtUtils::Manifest::manicheck() ], [], 'missing';
Test::More::is_deeply [ ExtUtils::Manifest::filecheck() ], [], 'extra';
