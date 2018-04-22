#!/usr/bin/env perl

use strict;
use warnings;

use FindBin qw($Bin);
use IPC::System::Simple qw(capturex);
use Test::More tests => 1;

# https://github.com/scrottie/autobox-Core/issues/34

$ENV{PERLDB_OPTS} = 'NonStop=1';

chomp(my $got = capturex($^X, '-d', "$Bin/debugger.pl"));
is $got, 'foo -> bar -> baz -> quux', 'runs under perl -d';
