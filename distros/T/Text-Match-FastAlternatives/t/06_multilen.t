#! /usr/bin/perl

use strict;
use warnings;

use Test::More tests => 12;
use Text::Match::FastAlternatives;

my @user_agents = read_lines('t/data/user_agents.txt');

{
    my $len = 0;
    for (my $i = 0;  $i < @user_agents;  $i++) {
        $len += length $user_agents[$i];
        if ($len >= 65537) {
            splice @user_agents, $i + 1;
            last;
        }
    }
    BAIL_OUT("Not enough UA data to build a big trie") if $len < 65537;
}

{
    my $tmfa = Text::Match::FastAlternatives->new($user_agents[0]);
    isa_ok($tmfa, 'Text::Match::FastAlternatives', 'tiny object');
    is($tmfa->pointer_length, 8, '... with 8-bit pointers');
    ok($tmfa->match("..$user_agents[0].."), '... and finds a match');
    ok(!$tmfa->match(''), q[... and doesn't find a non-match]);
}

{
    my @partial = @user_agents[0, 1];
    my $tmfa = Text::Match::FastAlternatives->new(@partial);
    isa_ok($tmfa, 'Text::Match::FastAlternatives', 'small object');
    is($tmfa->pointer_length, 16, '... with 16-bit pointers');
    ok($tmfa->match("..$partial[0].."), '... and finds a match');
    ok(!$tmfa->match(''), q[... and doesn't find a non-match]);
}

{
    my $tmfa = Text::Match::FastAlternatives->new(@user_agents);
    isa_ok($tmfa, 'Text::Match::FastAlternatives', 'large object');
    is($tmfa->pointer_length, 32, '... with 32-bit pointers');
    ok($tmfa->match("..$user_agents[-1].."), '... and finds a match');
    ok(!$tmfa->match(''), q[... and doesn't find a non-match]);
}

sub read_lines {
    my ($filename) = @_;
    open my $fh, '<', $filename
        or die "can't open $filename for reading: $!\n";
    my @lines = <$fh>;
    chomp @lines;
    return grep { $_ ne '' } @lines;
}
