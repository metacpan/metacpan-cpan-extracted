#!/usr/bin/perl

use 5.008;
use strict;
use warnings;
use utf8;

use Test::More;
use Test::Exception;

use Text::Lossy;

my $lossy = Text::Lossy->new;

is($lossy->process('Unchanged  text...'), 'Unchanged  text...', "Empty object does nothing");

$lossy->add();
is($lossy->process('Unchanged  text...'), 'Unchanged  text...', "Adding nothing still does nothing");

$lossy->add('lower');
is($lossy->process('Unchanged  text...'), 'unchanged  text...', "Added one filter");

$lossy->add('punctuation', 'whitespace');
is($lossy->process('Unchanged  text...'), 'unchanged text', "Added two more filters");

$lossy = Text::Lossy->new;

$lossy->add('punctuation')->add('whitespace');
is($lossy->process('Unchanged  text...'), 'Unchanged text', "Added two filters with chaining");

$lossy = Text::Lossy->new;
$lossy->add('lower', 'lower', 'lower');
is($lossy->process('Unchanged  text...'), 'unchanged  text...', "Added one filter three times");
is(scalar(@{$lossy->{filters}}), 3, "Counts three filters");

$lossy = Text::Lossy->new;
throws_ok {
    $lossy->add('no_such_filter');
} qr{unknown filter}ims, "Adding unknown filters causes an exception";

# Technically, every filter before an unknown one is still added.
# But we don't guarantee it, so we don't test it.

done_testing();
