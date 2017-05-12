#!/usr/bin/perl

use strict;
use warnings;
use Text::Karma;
use Test::More;

# Okay, build up the list of testcases for our parsing engine
my %tests = (
    # string to test against => arrayref
    #	arrayref holds hashrefs of results
    #		k => the karma string
    #		m => the mode (1 for ++,  0 for --)
    #		c => the comment
    #		TODO => 1, if present, treat this as TODO
    'foo++' => [
        {
            k => 'foo',
            m => 1,
            c => undef,
        },
    ],
    '(a foo)++' => [
        {
            k => 'a foo',
            m => 1,
            c => undef,
        },
    ],
    '(    a foo  )++' => [
        {
            k => 'a foo',
            m => 1,
            c => undef,
        },
    ],
    '(a foo)++ # nice!' => [
        {
            k => 'a foo',
            m => 1,
            c => 'nice!',
        },
    ],
    'this foo++ is nice' => [
        {
            k => 'foo',
            m => 1,
            c => undef,
        },
    ],
    'this foo++ is nice++ to know' => [
        {
            k => 'foo',
            m => 1,
            c => undef,
        },
        {
            k => 'nice',
            m => 1,
            c => undef,
        },
    ],
    'this foo++ is nice++ to know++ # haha' => [
        {
            k => 'foo',
            m => 1,
            c => undef,
        },
        {
            k => 'nice',
            m => 1,
            c => undef,
        },
        {
            k => 'know',
            m => 1,
            c => 'haha',
        },
    ],
    '(this foo)++ is nice++ to know++ # haha' => [
        {
            k => 'this foo',
            m => 1,
            c => undef,
        },
        {
            k => 'nice',
            m => 1,
            c => undef,
        },
        {
            k => 'know',
            m => 1,
            c => 'haha',
        },
    ],
    '(this foo)++ is nice++ (to know)++ # haha' => [
        {
            k => 'this foo',
            m => 1,
            c => undef,
        },
        {
            k => 'nice',
            m => 1,
            c => undef,
        },
        {
            k => 'to know',
            m => 1,
            c => 'haha',
        },
    ],
    'this foo++ # super! i like++ this' => [
        {
            k => 'foo',
            m => 1,
            c => 'super! i like++ this',
        },
    ],
    '(a foo)++ hi # c' => [
        {
            k => 'a foo',
            m => 1,
            c => undef,
        },
    ],
    'foo++ hey # c' => [
        {
            k => 'foo',
            m => 1,
            c => undef,
        },
    ],
    'hey foo++ (thi sis)++ # awesome super++ (thing and)++ # nice' => [
        {
            k => 'foo',
            m => 1,
            c => undef,
        },
        {
            k => 'thi sis',
            m => 1,
            c => 'awesome super++ (thing and)++ # nice',
        },
    ],
    'foo++ (super cool)++ # nice i like++ this awesome++ # stuff' => [
        {
            k => 'foo',
            m => 1,
            c => undef,
        },
        {
            k => 'super cool',
            m => 1,
            c => 'nice i like++ this awesome++ # stuff',
        },
    ],

    # those may be "incorrect" at first glance but it actually is the right behavior
    # as the comment is not for a karma, so we are "allowed" to parse it for the karma words
    # in it, and this makes things a bit more complicated
    'foo++ this # awesome comment++' => [
        {
            k => 'foo',
            m => 1,
            c => undef,
        },
        {
            k => 'comment',
            m => 1,
            c => undef,
        },
    ],
    '(a foo)++ this # comment++' => [
        {
            k => 'a foo',
            m => 1,
            c => undef,
        },
        {
            k => 'comment',
            m => 1,
            c => undef,
        },
    ],
    'foo++ this # awesome comment++ # hey' => [
        {
            k => 'foo',
            m => 1,
            c => undef,
        },
        {
            k => 'comment',
            m => 1,
            c => 'hey',
        },
    ],
    '(a foo)++ this # comment++ # hola' => [
        {
            k => 'a foo',
            m => 1,
            c => undef,
        },
        {
            k => 'comment',
            m => 1,
            c => 'hola',
        },
    ],
    '(a foo)++ this # comment++ # hola this++ should not work++ # another comment++' => [
        {
            k => 'a foo',
            m => 1,
            c => undef,
        },
        {
            k => 'comment',
            m => 1,
            c => 'hola this++ should not work++ # another comment++',
        },
    ],

    # Oh, a certain idiot just got a nice 60" tv and wants to brag... ;)
    '60"++' => [
        {
            k => '60"',
            m => 1,
            c => undef,
        },
    ],
);

# Count the number of tests we have
# one test to compare number of matches
# 3 tests per match to compare k/m/c
my $num_tests = 0;

# This is dirty, but we build the reverse testcase ( with -- )
for my $t (keys %tests) {
    my $reverse = $t;
    $reverse =~ s/\+\+/\-\-/g;
    $num_tests += 2;

    for my $match (@{ $tests{$t} }) {
        my $rev_c = $match->{'c'};
        $rev_c =~ s/\+\+/\-\-/g if defined $rev_c;
        push( @{ $tests{$reverse} }, {
            'k' => $match->{k},
            'm' => 0,
            'c' => $rev_c,
            (exists $match->{TODO} ? (TODO => 1) : ()),
        } );

        $num_tests += 6;
    }
}

# Start the actual testing!
plan tests => $num_tests;
my $karma = Text::Karma->new;
my $results;

# call the parser and analyze the data
for my $t (keys %tests) {
    $results = $karma->process_karma(
        nick => 'tester',
        who => 'tester@hlagh',
        where => '#test',
        str   => $t,
    );

    # compare it!
    if (exists $tests{$t}[0]{TODO}) {
        TODO: {
            local $TODO = "This part of the parser engine is still a todo";
            compare_results($t);
        }
    }
    else {
        compare_results($t);
    }

    # clear the results for the next run
    $results = undef;
}

sub compare_results {
    my $t = shift;

    # see if we have the same number of matches
    is(scalar @$results, scalar @{ $tests{$t} }, "parsed karma count for $t");

    # Compare each match
    for my $i (0..$#{ $tests{$t} }) {
        is($results->[$i]{subject}, $tests{$t}[$i]{k}, 'karma matches');
        is($results->[$i]{op}, $tests{$t}[$i]{m}, 'mode matches');

        # comment can be undef...
        if (!defined $tests{$t}[$i]{c}) {
            ok(!defined $results->[$i]->{comment}, 'comment matches');
        }
        else {
            is($results->[$i]->{comment}, $tests{$t}[$i]{c}, 'comment matches');
        }
    }
}

