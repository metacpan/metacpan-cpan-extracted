#! /usr/bin/perl

use strict;
use warnings;

use Test::More;

my @user_agents = read_lines('t/data/user_agents.txt');
my @robots      = read_lines('t/data/robots.txt');

plan tests => 1 + 2 * @user_agents;

use_ok('Text::Match::FastAlternatives');

my $tmfa   = Text::Match::FastAlternatives->new(@robots);
my $tmfa_i = Text::Match::FastAlternatives->new(map { lc } @robots);
my $rx     = build_regex(0, @robots);
my $rx_i   = build_regex(1, @robots);

for my $ua (@user_agents) {
    my $match_tmfa   = $tmfa->match($ua);
    my $match_rx     = $ua =~ $rx;
    ok($match_tmfa && $match_rx || !$match_tmfa && !$match_rx,
        "same case-sensitive result for UA '$ua'");
    my $match_tmfa_i = $tmfa_i->match(lc $ua);
    my $match_rx_i   = $ua =~ $rx_i;
    ok($match_tmfa_i && $match_rx_i || !$match_tmfa_i && !$match_rx_i,
        "same case-insensitive result for UA '$ua'");
}

sub read_lines {
    my ($filename) = @_;
    open my $fh, '<', $filename
        or die "can't open $filename for reading: $!\n";
    my @lines = <$fh>;
    chomp @lines;
    return @lines;
}

sub build_regex {
    my ($caseless, @items) = @_;
    my $rx = join '|', map { quotemeta } @items;
    return $caseless ? qr/$rx/i : qr/$rx/;
}
