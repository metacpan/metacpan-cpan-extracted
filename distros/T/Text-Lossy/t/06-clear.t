#!/usr/bin/perl

use 5.008;
use strict;
use warnings;
use utf8;

use Test::More;

use Text::Lossy;

my $lossy = Text::Lossy->new;

$lossy->add('lower');
is($lossy->process('Unchanged  text...'), 'unchanged  text...', "Added one filter");
is(scalar(@{$lossy->{filters}}), 1, "Counts one filters");

$lossy->clear();
is($lossy->process('Unchanged  text...'), 'Unchanged  text...', "Text unchanged");
is(scalar(@{$lossy->{filters}}), 0, "Counts zero filters");

$lossy->add('punctuation', 'whitespace', 'lower', 'lower');
is($lossy->process('Unchanged  text...'), 'unchanged text', "Added one filter three times");
is(scalar(@{$lossy->{filters}}), 4, "Added four filters to count four");

$lossy->clear();
is(scalar(@{$lossy->{filters}}), 0, "Added four filters to count four");

done_testing();
