#!perl

use strict;
use warnings;
use autodie;
use feature qw/ say /;
use Graph::Undirected;

sub main {

=pod

In this version, we use the C<Graph> module from CPAN.  It has a lot
of functionality but, at least in this case, is a good deal slower
than C<YAGL>.

=cut

    my $g     = Graph::Undirected->new;
    my @words = slurp('../data/words.dat');

=pod

First, we sort the words based on their "weights" (really, a
"checksum" which is just the sum of C<chr()> values).  See the
C<chksum()> subroutine below for the details.

This sorting step is necessary to help us later.  Later on, we will
use this sorted order, since it will mean we don't need to check every
word against every other word; we only need to check a word W against
all of the previous words W-1, W-2, ..., W-n.  How do we know which
words are "previous"?  Because we did the sorting step.

=cut

    my %chksum;
    for my $word (@words) {
        $chksum{$word} = chksum($word);
    }
    @words = sort { $chksum{$a} <=> $chksum{$b} } @words;

=pod

In this section, we generate the hash tables that will be used later
on to determine if two words are "adjacent" to one another in the
graph.  The question of adjacency we're using here is: are they the
same except for one letter?  For example, "grape" and "graph" are
adjacent, while "plane" and "plows" are not.

=cut

    my %words;
    for my $word (@words) {
        $g->add_vertex($word);
        my @word = split //, $word;
        for (my $i = 0; $i < @word; $i++) {
            my $c = $word[$i];
            $word[$i] = '_';
            my $variant = join '', @word;
            push @{$words{$variant}}, $word;
            $word[$i] = $c;
        }
    }

=pod

Now that we have tables storing all of the "holey variants" of each
word, we iterate over the table keys.  For each key, we add edges
between all of the values associated with that key.  This should work
because the data structure looks something like:

    {
      "_ords" => ["words", "cords", ...],
      ...,
    }

=cut

    my $edge_count = 0;
    for my $k (keys %words) {
        my $vertices = $words{$k};
        for (my $i = 0; $i < @$vertices; $i++) {
            for (my $j = 0; $j < $i; $j++) {
                my $u     = $vertices->[$i];
                my $v     = $vertices->[$j];
                my $v_sum = $chksum{$v};
                my $u_sum = $chksum{$u};
                my $weight
                  = $v_sum > $u_sum ? $v_sum - $u_sum : $u_sum - $v_sum;
                $g->add_weighted_edge($u, $v, $weight);
                $edge_count++;
            }
        }
    }

=pod

Now that the graph is built and populated, we can start operating on
it.  We will now look for a path from a starting word to some other
word by traversing a "word ladder", which in graph terms means we will
find the shortest path (based on the "checksums" calculated above)
using Dijkstra's algorithm.

Note that the structure of this graph matches that of the WORDS
program from the Stanford GraphBase, since it has 5757 vertices and
14135 edges.  However, the "distance" between words are different,
since we do not use the weighting system defined in SGB's F<words.dat>
-- we only used the word list and criteria for adding edges, and
calculate our own "checksum" for each word as mentioned previously.

=cut

    my $start = 'words';
    my $end   = 'graph';

    say qq[Looking for a path between '$start' and '$end'];
    my @path = $g->SP_Dijkstra($start, $end);

    say qq[PATH: ];
    say for @path;
}

sub chksum {
    ## String -> Integer
    my $word = shift;
    my $sum  = 0;
    for my $c (split //, $word) {
        $sum += ord($c);
    }
    return $sum;
}

sub slurp {
    ## Pathname -> Array
    my $f = shift;
    open my $in, '<', $f;
    local $/;
    my @lines = split /\n/, <$in>;
    close $in;
    return @lines;
}

=pod

Finally, we run the program.

=cut

main();

# Local Variables:
# compile-command: "perl ladders-g.pl"
# End:
