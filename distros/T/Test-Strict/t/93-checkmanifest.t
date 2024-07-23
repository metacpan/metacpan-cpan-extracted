use strict;
use warnings;
use Test::More tests => 2;
use ExtUtils::Manifest;

is_deeply [ ExtUtils::Manifest::manicheck() ], [], 'missing';
is_deeply [ ExtUtils::Manifest::filecheck() ], [], 'extra';
