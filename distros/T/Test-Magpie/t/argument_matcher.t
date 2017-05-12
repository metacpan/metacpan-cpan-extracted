#!/usr/bin/perl -T
use strict;
use warnings;

use Test::More tests => 6;
use Test::Fatal;

use MooseX::Types::Moose qw( Int );

use constant ArgumentMatcher => 'Test::Magpie::ArgumentMatcher';

BEGIN { use_ok ArgumentMatcher, qw(anything custom_matcher hash set type) }

subtest 'anything' => sub {
    my $matcher = anything;
    isa_ok $matcher, ArgumentMatcher;
    is $matcher, 'anything()', 'string overloads';

    is_deeply [$matcher->match(qw[arguments are ignored])], [], 'ignore args';
    is_deeply [$matcher->match()], [], 'no args';
};

subtest 'custom_matcher' => sub {
    my $matcher = custom_matcher {ref($_) eq 'ARRAY'};
    isa_ok $matcher, ArgumentMatcher;
    like $matcher, qr/custom_matcher\(CODE\(.+\)\)/, 'string overloads';

    is_deeply [$matcher->match([])], [], 'match';
    is $matcher->match(123), undef, 'no match';
    is $matcher->match(),    undef, 'no args';
};

subtest 'hash' => sub {
    my $matcher = hash(a => 1, b => 2, c => 3);
    isa_ok $matcher, ArgumentMatcher;
    like $matcher, qr/hash\([a1b2c3",\s]+\)/, 'string overloads';

    is_deeply [$matcher->match(a => 1, b => 2, c => 3)], [], 'match exactly';
    is_deeply [$matcher->match(c => 3, b => 2, a => 1)], [],
        'match different order';
    is $matcher->match(a => 1, b => 2),         undef, 'missing key';
    is $matcher->match(a => 1, b => 2, d => 3), undef, 'different key';
    is $matcher->match(a => 1, b => 2, c => 4), undef, 'different value';
    is $matcher->match(),                       undef, 'no args';
};

subtest 'set' => sub {
    my $matcher = set(1, 1, 2, 3, 4, 5);
    isa_ok $matcher, ArgumentMatcher;
    is $matcher, 'set(1, 1, 2, 3, 4, 5)', 'string overloads';

    is_deeply [$matcher->match(1, 1, 2, 3, 4, 5)], [], 'match exactly';
    is_deeply [$matcher->match(1, 2, 3, 4, 5)],    [], 'match unique set';
    is_deeply [$matcher->match(5, 4, 3, 2, 1)],    [], 'match different order';
    is $matcher->match(1, 2, 3, 4, 5, 6), undef, 'more args';
    is $matcher->match(1, 2, 3, 4),       undef, 'less args';
    is $matcher->match(2, 3, 4, 5, 6),    undef, 'different args';
    is $matcher->match(),                 undef, 'no args';
};

subtest 'type' => sub {
    my $matcher = type(Int);
    isa_ok $matcher, ArgumentMatcher;
    is $matcher, 'type(Int)', 'string overloads';

    is_deeply [$matcher->match(234)],   [], 'match Int';
    is_deeply [$matcher->match('234')], [], 'match Int (Str)';
    is $matcher->match(234.14),  undef, 'no match - Num';
    is $matcher->match('hello'), undef, 'no match - Str';
    is $matcher->match([234]),   undef, 'no match - ArrayRef';
    is $matcher->match(),        undef, 'no args';
};
