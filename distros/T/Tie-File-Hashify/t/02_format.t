#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 2;

use IO::File;
use Tie::File::Hashify;

my %rc;
my $ok;

$ok = tie(%rc, 'Tie::File::Hashify', undef, format => '- %s => %s');

ok($ok, 'tie worked');

$rc{foo} = 'bar';

ok(%rc eq "- foo => bar\n", 'format works');

untie %rc;
