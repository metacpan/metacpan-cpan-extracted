#! /usr/bin/perl

use strict;
use warnings;

# Currently this performance test produces the following results on my
# hardware:
#
#             Rate     rx rxtrie   tmfa
#   rx     0.539/s     --   -87%   -99%
#   rxtrie  4.14/s   667%     --   -95%
#   tmfa    76.5/s 14093%  1749%     --
#
# This isn't quite as good as I claim in the perldoc.  That's because I'm
# testing with fewer keys (246, not 339), and the regex solutions get slower as
# more keys are added, whereas Text::Match::FastAlternatives runs in time that
# is independent of the number of keys.

use blib;

use Text::Match::FastAlternatives;
use File::Slurp qw<read_file>;
use Benchmark qw<cmpthese>;
use List::MoreUtils qw<uniq>;

chomp(my @robots = read_file('t/data/robots.txt'));
chomp(my @uagents = uniq read_file('t/data/user_agents.txt'));

my $rx = do { my $rx = join '|', map { quotemeta } @robots; qr/$rx/i };
my $tmfa = Text::Match::FastAlternatives->new(map { lc } @robots);
my $trie_rx;

my %tests = (
    rx   => sub { for my $ua (@uagents) { my $matched = $ua =~ $rx } },
    tmfa => sub { for my $ua (@uagents) { my $matched = $tmfa->match(lc $ua) } },
);

if (eval { require Regexp::Trie }) {
    $tests{rxtrie} = sub {
        for my $ua (@uagents) { my $matched = lc $ua =~ $trie_rx }
    };
    my $rt = Regexp::Trie->new;
    $rt->add(lc $_) for @robots;
    $trie_rx = $rt->regexp;
}

cmpthese(-60, \%tests);
