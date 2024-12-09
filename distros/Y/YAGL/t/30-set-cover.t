#!/usr/bin/env perl

use strict;
use warnings;
use feature qw/ say /;
use lib 'lib';
use YAGL;
use Cwd;
use Test::More tests => 15;

use constant SKIP_BIG_TESTS => 1;

my $cwd = getcwd;

=head2 Test 1. Exact Cover from 'Algorithm X in 30 Lines!'

Adapted from "Algorithm X in 30 Lines!"

    my @options = qw/ adg ad deg ih bcef /;
    my @items = qw/ a b c d e f g h i /;
    my $is_exact = 1;

Should return:

    ('ih', 'adg', 'bcef')

=cut

my @options1  = qw/ adg ad deg ih bcef /;
my @items1    = qw/ a b c d e f g h i /;
my $is_exact1 = 1;

my $g1 = YAGL->new;

# Build the bipartite graph that represents the problem.

for my $option (@options1) {
    for ( my $i = 0; $i < scalar @items1; $i++ ) {
        my $item = $items1[$i];
        if ( $option =~ /$item/ ) {
            $g1->add_edge( $item, $option );
        }
    }
}

my @got1 = $g1->set_cover( is_exact => 1, n_solutions => 1 );

my $expected1 = [['adg', 'bcef', 'ih']];

is_deeply( \@got1, $expected1,
    "Exact cover example from 'Algorithm X in 30 Lines!'" );

=head2 Test 2. Exact Cover from Knuth

From Knuth (v4fasc5 p. 65)

    my @options = ('ce', 'adg', 'bcf', 'adf', 'bg', 'deg');
    my @items   = qw/a b c d e f g/;

Should return:

    ('ce', 'adf', 'bg')

=cut

my @options2  = ( 'ce', 'adg', 'bcf', 'adf', 'bg', 'deg' );
my @items2    = qw/a b c d e f g/;
my $is_exact2 = 1;

my $g2 = YAGL->new;

# Build the bipartite graph that represents the problem.

for my $option (@options2) {
    for ( my $i = 0; $i < scalar @items2; $i++ ) {
        my $item = $items2[$i];
        if ( $option =~ /$item/ ) {
            $g2->add_edge( $item, $option );
        }
    }
}

unless ( $g2->is_bipartite ) {
    die qq[Exact cover only works on bipartite graphs!];
}

# For Exact Cover problem, pass something truthy as optional final
# arg '$is_exact'

my @got2 = $g2->set_cover( is_exact => 1, n_solutions => 1 );
my $got2 = $got2[0];

my @expected2 = ['adf', 'bg', 'ce'];

is_deeply( \@got2, \@expected2, "Exact cover example from Knuth" );

=head2 Test 3. Counter-example for greedy algorithm for Set Cover

https://cs.stackexchange.com/questions/134714/counterexample-to-greedy-solution-for-set-cover-problem

=cut

my @items_3   = qw/ a b c d e f g h i  j  k  l  m  n  o  p /;
my @options_3 = qw/
  ab
  cdef
  ghijklmnop
  abcdefgh
  ijklmnop
  /;
my $is_exact3 = 1;

my $g3 = YAGL->new;

# Build the bipartite graph that represents the problem.

for my $option (@options_3) {
    for ( my $i = 0; $i < scalar @items_3; $i++ ) {
        my $item = $items_3[$i];
        if ( $option =~ /$item/ ) {
            $g3->add_edge( $item, $option );
        }
    }
}

# For Exact Cover problem, pass something truthy as optional final
# arg '$is_exact'

my @got_3 = $g3->set_cover( is_exact => $is_exact3, n_solutions => 1 );

my $expected_3 = [['abcdefgh', 'ijklmnop']];

is_deeply( \@got_3, $expected_3,
    "Counter-example for greedy algorithm for set cover" );

=head2 Test 4. Set Cover: A Toy Example (Inexact cover)

From https://2018.erum.io/slides/lightning%20talks/Matthias%20Kaeding.pdf

Inexact cover is (length 2): 'abef cde'

=cut

my @items4   = qw/ a b c d e f /;
my @options4 = qw/
  abef
  cde
  abc
  bd
  /;
my $is_exact4 = undef;

my $g4 = YAGL->new;

# Build the bipartite graph that represents the problem.

for my $option (@options4) {
    for ( my $i = 0; $i < scalar @items4; $i++ ) {
        my $item = $items4[$i];
        if ( $option =~ /$item/ ) {
            $g4->add_edge( $item, $option );
        }
    }
}

my @got4 = $g4->set_cover( is_exact => $is_exact4, n_solutions => 1 );

my $expected4 = [['abef', 'cde']];

is_deeply( \@got4, $expected4,
    "Set cover: a toy example (tiny inexact cover)" );

=head2 Test 5. Graph vertex cover

Example 2. We can reduce any graph vertex cover problem to set cover:

- The vertices of the graph are the ITEMS.

- The edges of the graph incident to each vertex are the OPTIONS.

     0-1-2-3
       | | |
       4-5-6
           |
           7

main: exact cover of items 'a b c d e f g h'
      is (length 4): 'gh ef cd ab'

=cut

my @items5   = qw/ a b c d e f g h /;
my @options5 = qw/
  ab
  bc
  be
  ef
  cf
  cd
  fg
  dg
  gh
  /;
my $is_exact5 = 1;

my $g5 = YAGL->new;

# Build the bipartite graph that represents the problem.

for my $option (@options5) {
    for ( my $i = 0; $i < @items5; $i++ ) {
        my $item = $items5[$i];
        if ( $option =~ /$item/ ) {
            $g5->add_edge( $item, $option );
        }
    }
}

unless ( $g5->is_bipartite ) {
    die qq[Set cover only works on bipartite graphs!];
}

my @got5 = $g5->set_cover( is_exact => $is_exact5, n_solutions => 1 );

my $expected5 = [['ab', 'cd', 'ef', 'gh']];

is_deeply( \@got5, $expected5, "Graph vertex cover" );

=head2 Test 6. Find the smallest team of Software developers

Adapted from:
https://www.comp.nus.edu.sg/~stevenha/cs4234/lectures/03a.SetCover.pdf

Example 1. Find the smallest team of Software developers who will
cover all of the following languages: C (c), C++ (d), Java (j), Python
(p), Ruby (r)

main: exact cover of items 'c d j r p' is (length 2): 'drp cj'

=cut

my @items6    = qw/ c d j r p /;
my @options6  = qw/ cd dj drp cj /;
my $is_exact6 = 1;

my $g6 = YAGL->new;

# Build the bipartite graph that represents the problem.

for my $option (@options6) {
    for ( my $i = 0; $i < @items6; $i++ ) {
        my $item = $items6[$i];
        if ( $option =~ /$item/ ) {
            $g6->add_edge( $item, $option );
        }
    }
}

unless ( $g6->is_bipartite ) {
    die qq[Set cover only works on bipartite graphs!];
}

my @got6 = $g6->set_cover( is_exact => $is_exact6, n_solutions => 1 );

my $got6 = $got6[0];
@$got6 = sort { $a cmp $b } @$got6;

my @expected6 = ['cj', 'drp'];

is_deeply( \@got6, \@expected6,
    "Find the smallest team of Software developers" );

=head2 Test 7. An inexact set cover

Adapted from:
https://www.comp.nus.edu.sg/~stevenha/cs4234/lectures/03a.SetCover.pdf

"... the optimal set cover consists of only three elements: S1, S4, S5."

main: (possibly inexact) cover of items 'a b c d e f g h i j k l'
      is (length 3): 'cfil bcehk adgj'

=cut

my @items7   = qw/ a b c d e f g h i j k l /;
my @options7 = qw/
  adgj
  defghi
  jkl
  bcehk
  cfil
  /;
my $is_exact7 = undef;

my $g7 = YAGL->new;

# Build the bipartite graph that represents the problem.

for my $option (@options7) {
    for ( my $i = 0; $i < @items7; $i++ ) {
        my $item = $items7[$i];
        if ( $option =~ /$item/ ) {
            $g7->add_edge( $item, $option );
        }
    }
}

unless ( $g7->is_bipartite ) {
    die qq[Set cover only works on bipartite graphs!];
}

my @got7 = $g7->set_cover( is_exact => $is_exact7, n_solutions => 1 );

my $got7 = $got7[0];
@$got7 = sort { $a cmp $b } @$got7;

my @expected7 = ( 'adgj', 'bcehk', 'cfil' );

is_deeply( $got7, \@expected7, "Inexact set cover" );

=head2 Test 8. Set Cover and Applications to Shortest Superstring (Problem 1)

Adapted from L<https://www.cs.dartmouth.edu/~ac/Teach/CS105-Winter05/Notes/wan-ba-notes.pdf>

Problem 1. Optimal cover is {S3, S4, S5} (found below)

main: inexact cover of items 'a b c d e f g h i j k l'
      is (length 3): 'ijkl cefgh abcd'

=cut

my @items8   = qw/ a b c d  e f g h  i  j  k  l /;
my @options8 = (

    # s1
    'abefij',

    # s2
    'fgjk',

    # s3 *
    'abcd',

    # s4 *
    'cefgh',

    # s5 *
    'ijkl',

    # s6
    'dh',
);

my $is_exact8 = undef;

my $g8 = YAGL->new;

# Build the bipartite graph that represents the problem.

for my $option (@options8) {
    for ( my $i = 0; $i < @items8; $i++ ) {
        my $item = $items8[$i];
        if ( $option =~ /$item/ ) {
            $g8->add_edge( $item, $option );
        }
    }
}

my @got8 = $g8->set_cover( is_exact => $is_exact8, n_solutions => 1 );

my $expected8 = [['abcd', 'cefgh', 'ijkl']];

is_deeply( \@got8, $expected8,
    "Set Cover and Applications to Shortest Superstring (Problem 1)" );

=head2 Test 9. Set Cover and Applications to Shortest Superstring (Problem 2)

Adapted from L<https://www.cs.dartmouth.edu/~ac/Teach/CS105-Winter05/Notes/wan-ba-notes.pdf>

Problem 2. Optimal cover is {t1,t3,t2} (see below).
main: inexact cover of items 'a b c d e f g h i'
      is (length 3): 'efghi abdegh abcde'

=cut

my @items9   = qw/ a b c d e f g h i /;
my @options9 = (

    # t1
    'abdegh',

    # t2
    'abcde',

    # t3
    'efghi',

    # t4
    'hi',
);
my $is_exact9 = undef;

my $g9 = YAGL->new;

# Build the bipartite graph that represents the problem.

for my $option (@options9) {
    for ( my $i = 0; $i < @items9; $i++ ) {
        my $item = $items9[$i];
        if ( $option =~ /$item/ ) {
            $g9->add_edge( $item, $option );
        }
    }
}

my @got9 = $g9->set_cover( is_exact => $is_exact9, n_solutions => 1 );

my $expected9 = [['abcde', 'efghi']];

is_deeply( \@got9, $expected9,
    "Set Cover and Applications to Shortest Superstring (Problem 2)" );

=head2 Test 10. Set Cover Example from Syslo

Adapted from p. 182 of I<Discrete Optimization Algorithms (with Pascal Programs)> by Syslo et al

main: exact cover of items 'a b c d e' is 'ace bd'

=cut

my @items10   = qw/ a b c d e /;
my @options10 = qw/
  ace
  bd
  ce
  cd
  ac
  ace
  /;
my $is_exact10 = 1;

my $g10 = YAGL->new;

# Build the bipartite graph that represents the problem.

for my $option (@options10) {
    for ( my $i = 0; $i < @items10; $i++ ) {
        my $item = $items10[$i];
        if ( $option =~ /$item/ ) {
            $g10->add_edge( $item, $option );
        }
    }
}

my @got10 = $g10->set_cover( is_exact => $is_exact10, n_solutions => 1 );

my $expected10 = [['ace', 'bd']];

is_deeply( \@got10, $expected10, "Set Cover Example from Syslo" );

=head2 Test 11. Cornell optimization example

Adapted from the "Numerical Example" section of
L<https://optimization.cbe.cornell.edu/index.php?title=Set_covering_problem>

Solution1: z1,z3,z5,z6
Solution2: z2,z3,z4,z5

Solution 1: 'hno beikm cfjln acdfg'
Solution 2: 'abno beikm cfjln dghl'

=cut

my @items11   = qw/ a b c d e f g h i  j  k  l  m  n  o /;
my @options11 = (

    # 1,3,4,6,7 (z1)
    'acdfg',

    # 4,7,8,12 (z2)
    'dghl',

    # 2,5,9,11,13 (z3)
    'beikm',

    # 1,2,14,15 (z4)
    'abno',

    # 3,6,10,12,14 (z5)
    'cfjln',

    # 8,14,15 (z6)
    'hno',

    # 1,2,6,11 (z7)
    'abfk',

    # 1,2,4,6,8,12 (z8)
    'abdfhl',
);
my $is_exact11 = undef;

my $g11 = YAGL->new;

# Build the bipartite graph that represents the problem.

for my $option (@options11) {
    for ( my $i = 0; $i < @items11; $i++ ) {
        my $item = $items11[$i];
        if ( $option =~ /$item/ ) {
            $g11->add_edge( $item, $option );
        }
    }
}

my @got11 = $g11->set_cover( is_exact => $is_exact11, n_solutions => 2 );

my $expected11
  = [['abno', 'beikm', 'cfjln', 'dghl'], ['acdfg', 'beikm', 'cfjln', 'hno']];

is_deeply( \@got11, $expected11, "Cornell optimization example" );

=head2 Test 12. Greedy Approximation - Set Cover (UMD)

Problem adapted from Fig. 1 of
L<https://www.cs.umd.edu/class/fall2017/cmsc451-0101/Lects/lect09-set-cover.pdf>

=cut

my @items12    = qw/ a b c d e f g h i j k l /;
my @options12  = qw/ abefij fgjk abcd efgh ijkl dhl /;
my $is_exact12 = 1;

my $g12 = YAGL->new;

# Build the bipartite graph that represents the problem.

for my $option (@options12) {
    for ( my $i = 0; $i < @items12; $i++ ) {
        my $item = $items12[$i];
        if ( $option =~ /$item/ ) {
            $g12->add_edge( $item, $option );
        }
    }
}

my @got12 = $g12->set_cover( is_exact => $is_exact12, n_solutions => 1 );

my $expected12 = [['abcd', 'efgh', 'ijkl']];

is_deeply( \@got12, $expected12, "Greedy Approximation - Set Cover (UMD)" );

=head2 Test 13. Dutta thesis example

Adapted from p. 9 of L<https://digital.library.unt.edu/ark:/67531/metadc12118/m2/1/high_res_d/thesis.pdf>

=cut

my @items13   = qw/ a b c d e f g h i j k l /;
my @options13 = (
    'abcdef',    # s1
    'efhi',      # s2
    'adgj',      # s3
    'beghk',     # s4
    'cfil',      # s5
    'jk',        # s6
);
my $is_exact13 = undef;

my $g13 = YAGL->new;

# Build the bipartite graph that represents the problem.

for my $option (@options13) {
    for ( my $i = 0; $i < @items13; $i++ ) {
        my $item = $items13[$i];
        if ( $option =~ /$item/ ) {
            $g13->add_edge( $item, $option );
        }
    }
}

my @got13 = $g13->set_cover( is_exact => $is_exact13, n_solutions => 1 );

my $expected13 = [['adgj', 'beghk', 'cfil']];

is_deeply( \@got13, $expected13, "Dutta thesis example" );

=head2 Test 14. Basic Modeling for Discrete Optimization 1.2.2

Adapted from lecture 1.2.2 of L<https://coursera.org/>

=cut

my @items14    = qw/ a b c d e f g h i j /;
my @options14  = qw/ adf abfg acfh abc aij   efhj   ghj   ace /;
my $is_exact14 = undef;

my $g14 = YAGL->new;

# Build the bipartite graph that represents the problem.

for my $option (@options14) {
    for ( my $i = 0; $i < @items14; $i++ ) {
        my $item = $items14[$i];
        if ( $option =~ /$item/ ) {
            $g14->add_edge( $item, $option );
        }
    }
}

my @got14 = $g14->set_cover( is_exact => $is_exact14, n_solutions => 1 );

my $expected14 = [['abc', 'abfg', 'adf', 'aij', 'efhj']];

is_deeply( \@got14, $expected14,
    "Basic Modeling for Discrete Optimization 1.2.2" );

=head2 Test 15. Rule 1R. Zero Rows

Per [Syslo84]: If there is an item for which there is no option whose
elements cover that item, then no solution exists.

=cut

my @items15    = qw/ a b c d e f g h i j z /;
my @options15  = qw/ adf abfg acfh abc aij efhj ghj ace /;
my $is_exact15 = 1;

my $g15 = YAGL->new;

# Build the bipartite graph that represents the problem.

for my $option (@options15) {
    for ( my $i = 0; $i < @items15; $i++ ) {
        my $item = $items15[$i];
        if ( $option =~ /$item/ ) {
            $g15->add_edge( $item, $option );
        }
    }
}

my @got15 = $g15->set_cover( is_exact => $is_exact15, n_solutions => 1 );

my $expected15 = [];

is_deeply( \@got15, $expected15, "Rule 1R. Zero Rows" );

=head2 Test 16. Set Cover Algorithms for Very Large Datasets

http://dimacs.rutgers.edu/~graham/pubs/papers/ckw.pdf

Data set modified down to 26 items and about 1600 options from
http://fimi.uantwerpen.be/data/chess.dat

Example 1. Covering 26 items with 1598 options

HOLY SHIT THIS ACTUALLY WORKS!!!1!

Best result so far: 6 options that cover the items (alphabet)

main: (possibly inexact) cover of items 'a b c d e f g h i j k l m n
o p q r s t u v w x y z' is (length 6): 'acegiknoqtuwz adegikmoqsuxy
bcegiknoqsvwy bcegiknprtuwy acegjlnoqsuwy bdfhikmoqsuwy'

23:43:23 - 23:43:41 (about 18 seconds)

=cut

do {

    my $infile = qq[$cwd/data/chess.smallest.pl];
    my ( $items16, $options16 ) = do $infile;

    say qq[Can't open $infile: $!] if $!;

    my $is_exact16 = undef;

    my $g16 = YAGL->new;

    # Build the bipartite graph that represents the problem.

    for my $option (@$options16) {
        for ( my $i = 0; $i < @$items16; $i++ ) {
            my $item = $items16->[$i];
            if ( $option =~ /$item/ ) {
                $g16->add_edge( $item, $option );
            }
        }
    }

    unless ( $g16->is_bipartite ) {
        die qq[Set cover only works on bipartite graphs!];
    }

    my @got16 = $g16->set_cover( is_exact => $is_exact16, n_solutions => 1 );
    @got16 = sort { $a cmp $b } @got16;

    say qq[GOT16: @got16];

    my $expected16 = [
        [
            'acegikmoqsuwy', 'acegikmoqsuwz',
            'acegikmoqtuwy', 'acegilmoqsvwy',
            'acegilmpqsuwy', 'acegilmprtuwy',
            'acegjlnoqsuwy', 'acehiknoqsuwy',
            'acfgikmoqsuwy', 'adegikmoqsuxy',
            'bcegikmoqsuwy',
        ]
    ];

    is_deeply( \@got16, \@$expected16,
        "Set Cover Algorithms for Very Large Datasets" );

} unless SKIP_BIG_TESTS;

# Local Variables:
# compile-command: "cd .. && perl t/30-set-cover.t"
# End:
