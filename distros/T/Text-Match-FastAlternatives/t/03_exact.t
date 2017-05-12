#! /usr/bin/perl

use strict;
use warnings;

use Test::More;

my $alphabet = join '', map { chr } 32 .. 126;

my %tmfa = (
    null     => [],
    empty    => [ '' ],
    alphabet => [ $alphabet ],
    prefixes => [ qw<foo foobar> ],
);

my @tests = (
    [null     => '',            0],
    [null     => 'foo',         0],
    [empty    => '',            1],
    [empty    => 'a',           0],
    [empty    => 'abc',         0],
    [empty    => $alphabet,     0],
    [alphabet => '',            0],
    [alphabet => $alphabet,     1],
    [alphabet => " $alphabet",  0, 'left-padded alphabet'],
    [alphabet => "$alphabet ",  0, 'right-padded alphabet'],
    [alphabet => " $alphabet ", 0, 'both-padded alphabet'],
    [prefixes => '',            0],
    [prefixes => 'f',           0],
    [prefixes => 'z',           0],
    [prefixes => 'fo',          0],
    [prefixes => 'foo',         1],
    [prefixes => 'foob',        0],
    [prefixes => 'fooba',       0],
    [prefixes => 'foobar',      1],
    [prefixes => 'foobarx',     0],
);

for my $matcher (keys %tmfa) {
    push @tests, map { [$matcher => chr($_), 0, "character $_"] }
        0x00, 0x0A, 0x1F, 0x7F, 0x80, 0xA0, 0xFF, 0x100, 0x200;
}

plan tests => 1 + @tests;

use_ok('Text::Match::FastAlternatives');

$_ = Text::Match::FastAlternatives->new(@$_) for values %tmfa;

for my $t (@tests) {
    my ($matcher, $target, $expected, $noun) = @$t;
    $noun ||= $target eq ''        ? 'empty string'
            : $target eq $alphabet ? 'alphabet'
            :                        "'$target'";
    my $message = $expected ? "$noun exact-matches $matcher"
                :             "$noun doesn't exact-match $matcher";
    my $result = $tmfa{$matcher}->exact_match($target);
    ok(!$result == !$expected, $message);
}
