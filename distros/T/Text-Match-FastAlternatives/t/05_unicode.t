#! /usr/bin/perl

use strict;
use warnings;

use Test::More;
use Encode qw<_utf8_on>;

BEGIN {
    binmode Test::More->builder->output,         ':utf8';
    binmode Test::More->builder->failure_output, ':utf8';
}

my @cities = read_lines('t/data/cities.txt');
my @yapc   = read_lines('t/data/yapc.txt');

plan tests => 2 + 2 * @cities;

use_ok('Text::Match::FastAlternatives');

my $tmfa   = Text::Match::FastAlternatives->new(@yapc);
my $tmfa_i = Text::Match::FastAlternatives->new(map { lc } @yapc);
my $rx     = build_regex(0, @yapc);
my $rx_i   = build_regex(1, @yapc);

for my $line (@cities) {
    my $match_tmfa   = $tmfa->match($line);
    my $match_rx     = $line =~ $rx;
    ok($match_tmfa && $match_rx || !$match_tmfa && !$match_rx,
        "same case-sensitive result for '$line'");
    my $match_tmfa_i = $tmfa_i->match(lc $line);
    my $match_rx_i   = $line =~ $rx_i;
    ok($match_tmfa_i && $match_rx_i || !$match_tmfa_i && !$match_rx_i,
        "same case-insensitive result for '$line'");
}

{
    my $str = "\xFF";
    _utf8_on($str);
    my $tmfa = eval { Text::Match::FastAlternatives->new($str) };
    my $exn = $@;
    ok(!defined $tmfa, "Can't create object for malformed 0xFF byte");
}

sub build_regex {
    my ($caseless, @items) = @_;
    my $rx = join '|', map { quotemeta } @items;
    return $caseless ? qr/$rx/i : qr/$rx/;
}

sub read_lines {
    my ($filename) = @_;
    open my $fh, '<:utf8', $filename
        or die "can't open $filename for reading: $!\n";
    my @lines = <$fh>;
    chomp @lines;
    return @lines;
}
