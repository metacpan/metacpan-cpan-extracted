#! /usr/bin/perl

use strict;
use warnings;

use Test::More;

BEGIN {
    binmode Test::More->builder->output,         ':utf8';
    binmode Test::More->builder->failure_output, ':utf8';
}

my $alphabet = join '', map { chr } 32 .. 126;

my %tmfa = (
    null     => [],
    empty    => [ '' ],
    a        => [ 'a' ],
    alphabet => [ $alphabet ],
    prefixes => [ qw<foo foobar> ],
    section  => [ "\xA7" ],
);

my @tests = (
    [null     =>  0, '',            0],
    [null     =>  1, '',            0],
    [null     =>  2, '',            0],
    [null     =>  0, 'foo',         0],
    [null     =>  1, 'foo',         0],
    [null     =>  2, 'foo',         0],
    [null     =>  3, 'foo',         0],
    [null     =>  4, 'foo',         0],
    [empty    =>  0, '',            1],
    [empty    =>  1, '',            0],
    [empty    =>  2, '',            0],
    [empty    =>  0, 'foo',         1],
    [empty    =>  1, 'foo',         1],
    [empty    =>  2, 'foo',         1],
    [empty    =>  3, 'foo',         1],
    [empty    =>  4, 'foo',         0],
    [a        =>  0, '',            0],
    [a        =>  1, '',            0],
    [a        =>  0, 'a',           1],
    [a        =>  1, 'a',           0],
    [a        =>  2, 'a',           0],
    [a        =>  0, $alphabet,     0],
    [a        =>  1, $alphabet,     0],
    [a        =>  2, $alphabet,     0],
    [a        => 64, $alphabet,     0],
    [a        => 65, $alphabet,     1],
    [a        => 66, $alphabet,     0],
    [a        => 95, $alphabet,     0],
    [a        => 96, $alphabet,     0],
    [a        => 97, $alphabet,     0],
    [alphabet =>  0, '',            0],
    [alphabet =>  1, '',            0],
    [alphabet =>  0, $alphabet,     1],
    [alphabet =>  1, $alphabet,     0],
    [alphabet =>  0, "$alphabet.",  1, 'right-padded alphabet'],
    [alphabet =>  1, "$alphabet.",  0, 'right-padded alphabet'],
    [alphabet =>  0, ".$alphabet",  0, 'left-padded alphabet'],
    [alphabet =>  1, ".$alphabet",  1, 'left-padded alphabet'],
    [alphabet =>  2, ".$alphabet",  0, 'left-padded alphabet'],
    [alphabet =>  0, ".$alphabet.", 0, 'left-padded alphabet'],
    [alphabet =>  1, ".$alphabet.", 1, 'both-padded alphabet'],
    [alphabet =>  2, ".$alphabet.", 0, 'both-padded alphabet'],
    [prefixes =>  0, '',            0],
    [prefixes =>  1, '',            0],
    [prefixes =>  0, 'f',           0],
    [prefixes =>  0, 'fo',          0],
    [prefixes =>  0, 'foo',         1],
    [prefixes =>  0, 'foob',        1],
    [prefixes =>  0, 'fooba',       1],
    [prefixes =>  0, 'foobar',      1],
    [prefixes =>  0, 'foobarx',     1],
    [prefixes =>  1, '',            0],
    [prefixes =>  1, 'f',           0],
    [prefixes =>  1, 'fo',          0],
    [prefixes =>  1, 'foo',         0],
    [prefixes =>  1, 'foob',        0],
    [prefixes =>  1, 'fooba',       0],
    [prefixes =>  1, 'foobar',      0],
    [prefixes =>  1, 'foobarx',     0],
    [section  =>  0, '',            0],
    [section  =>  1, '',            0],
    [section  =>  0, 'foo',         0],
    [section  =>  0, "\xA7.1.2",    1],
    [section  =>  1, "\xA7.1.2",    0],
    [section  =>  0, " \xA7.1.2",   0],
    [section  =>  1, " \xA7.1.2",   1],
    [section  =>  0, "\xA9\xA7",    0],
    [section  =>  1, "\xA9\xA7",    1],
    [section  =>  2, "\xA9\xA7",    0],
    [section  =>  3, "\xA9\xA7",    0],
    [section  =>  4, "\xA9\xA7",    0],
);

plan tests => 1 + @tests;

use_ok('Text::Match::FastAlternatives');

$_ = Text::Match::FastAlternatives->new(@$_) for values %tmfa;

for my $t (@tests) {
    my ($matcher, $pos, $target, $expected, $noun) = @$t;
    $noun ||= $target eq ''        ? 'empty string'
            : $target eq $alphabet ? 'alphabet'
            :                        "'$target'";
    my $message = $expected ? "$matcher matches $noun at $pos"
                :             "$matcher doesn't match $noun at $pos";
    my $result = $tmfa{$matcher}->match_at($target, $pos);
    ok(!$result == !$expected, $message);
}
