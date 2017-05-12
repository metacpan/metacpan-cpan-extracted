#!/usr/bin/perl

use strict;
use warnings;
use utf8;
use open qw(:std :utf8);

use Test::More tests => 1;

use Test::Whitespaces { _only_load => 1 };

my $version = $Test::Whitespaces::VERSION;

$version = "(unknown version)" if not defined $version;

ok(1, "Testing Test::Whitespaces $version, Perl $], $^X" );
