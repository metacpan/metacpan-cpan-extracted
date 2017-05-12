#!/usr/bin/perl

use 5.008;
use strict;
use warnings;
use utf8;
use open 'IO' => ':utf8';
use open ':std';

use Test::More;

use Text::Lossy;

my $lossy = Text::Lossy->new;
my @results;
my $result;

@results = $lossy->process();
ok(@results == 0, 'Empty list in, empty list out.');
@results = $lossy->process(undef);
ok(@results == 1, 'undef gives one result');
ok(!defined $results[0], 'That one result is undef');

$result = $lossy->process();
ok(!defined $result, 'Empty list gives undef in scalar context');
$result = $lossy->process(undef);
ok(!defined $result, 'undef gives undef in scalar context');

done_testing();
