#!/usr/bin/env perl

# https://github.com/scrottie/autobox-Core/issues/34

use strict;
use warnings;

use FindBin qw($Bin);
use IPC::System::Simple qw(capturex);
use Test::More tests => 1;

$ENV{PERLDB_OPTS} = 'NonStop=1';

chomp(my $got = capturex($^X, '-d', "$Bin/debugger.pl"));
like($got, qr{\bfoo -> bar -> baz -> quux\b}, 'runs under perl -d');
