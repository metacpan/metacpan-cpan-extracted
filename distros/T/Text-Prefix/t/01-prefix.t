#!/bin/env perl

use strict;
use warnings;
use Test::Most;
use JSON::PP qw(encode_json);

use lib "./lib";
use Text::Prefix;

my $p = Text::Prefix->new();
my $s = $p->prefix('foo');
ok $s =~ /^\w\w\w \w\w\w .\d \d\d:\d\d:\d\d \d\d\d\d \d+ foo$/, "prefix works in simple case ($s)";

$p = Text::Prefix->new(host_sans => '.', perl => '1', order => 'lt, tm, pl, d', tai => '35');
$s = $p->prefix('foo');
ok $s =~ /^\w\w\w \w\w\w .\d \d\d:\d\d:\d\d \d\d\d\d \d+\.\d+ 1 foo$/, "prefix works in complex case ($s)";

$p = Text::Prefix->new(no_date => 1, with => 'bar');
$s = $p->prefix('foo');
ok $s =~ /^bar foo$/, "prefix dates are optional ($s)";

done_testing();
exit(0);
