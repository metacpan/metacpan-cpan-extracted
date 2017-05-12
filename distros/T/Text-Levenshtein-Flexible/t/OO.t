#!/usr/bin/perl
use strict;
use warnings;
use utf8;

use Test::More tests => 34;
use Test::Exception;
use Test::LeakTrace;

BEGIN { use_ok('Text::Levenshtein::Flexible', qw/ :all /) };

# new and DESTROY
lives_ok(sub {
    is(_new(1, 2, 4, 6)->distance('aaa', 'abab'), 2, 'Simple distance calculation');
}, "new/DESTROY cycle");

# Simple calculations
my $t = _new(100, 2, 4, 6);
dies_ok(sub { $t->distance('a'x20000, 'b') }, 'Max string size enforced for src in distance()');
dies_ok(sub { $t->distance('a', 'b'x20000) }, 'Max string size enforced for dst in distance()');

# Distance-limited methods
is(_new(3, 2, 4, 6)->distance_l('aaa', 'abab'), 2, 'Limited distance with limit > dist');
is(_new(2, 2, 4, 6)->distance_l('aaa', 'abab'), 2, 'Limited distance with limit == dist');
is(_new(1, 2, 4, 6)->distance_l('aaa', 'abab'), undef, 'Limited distance with limit < dist');

$t = _new(100000, 2, 4, 6);
dies_ok(sub { $t->distance_l('a'x20000, 'b') }, 'Max string size enforced for src in distance_l()');
dies_ok(sub { $t->distance_l('a', 'b'x20000) }, 'Max string size enforced for dst in distance_l()');
dies_ok(sub { $t->distance_c('a'x20000, 'b') }, 'Max string size enforced for src in distance_c()');
dies_ok(sub { $t->distance_c('a', 'b'x20000) }, 'Max string size enforced for dst in distance_c()');
dies_ok(sub { $t->distance_lc('a'x20000, 'b') }, 'Max string size enforced for src in distance_lc()');
dies_ok(sub { $t->distance_lc('a', 'b'x20000) }, 'Max string size enforced for dst in distance_lc()');

# Costs
is(_new(100, 1, 100, 100)->distance_c('xxxx', 'xxaxx'), 1, 'Costs: insert');
is(_new(100, 100, 1, 100)->distance_c('xxaxx', 'xxxx'), 1, 'Costs: delete');
is(_new(100, 100, 100, 1)->distance_c('xxaxx', 'xxbxx'), 1, 'Costs: substitute');

# List methods
my @teststrings = qw/ axb axxxxxb abcde ab a 123456 /;
is_deeply(
    [ _new(3, 2, 2, 2)->distance_l_all('abc', @teststrings) ],
    [ ['axb', 2], ['abcde', 2], ['ab', 1], ['a', 2]],
    "Returning all matches in distance_l_all()"
);

is_deeply(
    [ _new(8, 2, 4, 8)->distance_lc_all('abc', @teststrings) ],
    [ [ 'axb', 6 ], [ 'abcde', 4 ], [ 'ab', 4 ], [ 'a', 8 ] ],
    "Returning all matches in distance_lc_all()"
);

no_leaks_ok(sub { _new(8, 2, 4, 8)->distance_lc_all('abc', @teststrings) }, 'no memory leaks in distance_lc_all');
no_leaks_ok(sub { _new(3)->distance_l_all('abc', @teststrings) }, 'no memory leaks in distance_lc_all');

# Partial arguments to new()
my @args = (10, 2, 3, 4);
do {
    lives_ok(
        sub { is(_new(@args)->distance('abc', 'abd'),1, "Correct distance with default args") },
        @args."-arg new()"
    );
} while(pop @args);

# Unicode
is(_new()->distance('Käßwåfer', 'Kaeswaafer'), 5, "Unicode strings, Latin");
is(_new()->distance('猫', '尻'), 1, "Unicode strings, Kanji");
is(_new()->distance('한글', '조선글'), 2, "Unicode strings, Hangul");

sub _new { return Text::Levenshtein::Flexible->new(@_) }
