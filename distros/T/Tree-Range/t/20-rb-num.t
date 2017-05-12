### 20-rb-num.t --- Test <=>-based Tree::Range::RB  -*- Perl -*-

use strict;
use warnings;

use Test::More qw (tests 33);

require_ok ("Tree::Range::RB");

sub ncmp {
    ## .
    $_[0] <=> $_[1];
}

sub value_equal_p {
    my ($a, $b) = @_;
    ## .
    return ($a eq $b);
}

my ($cmp, $leftmost, $value_equal_p)
    = (\&ncmp, [ "*leftmost*" ], \&value_equal_p);
my $rat_options = {
    "cmp"       => $cmp,
    "leftmost"  => $leftmost,
    "equal-p"   => $value_equal_p
};
my $rat
    = new_ok ("Tree::Range::RB", [ $rat_options ],
              "Tree::RB-based range tree");

isa_ok ($rat->backend (), "Tree::RB",
        "associated backend tree object");
is ($rat->cmp_fn, $cmp,
    "associated comparison function");
is ($rat->leftmost_value, $leftmost,
    "associated leftmost value");

is_deeply ([ $rat->get_range (42) ],
           [ $leftmost ],
           "unbounded range retrieved from the still empty range tree");

sub rat_kv {
    my @r
        = ();
    my $it
        = $rat->backend ()->iter ();
    while (my $e = $it->next ()) {
        push (@r, $e->key (), $e->val ());
    }
    ## .
    @r;
}

is_deeply ([ rat_kv () ], [ ],
           "the empty tree's backend is itself empty");

my @range_tests_1
    = ([ 31415, 3.1, 5, 4.1, $leftmost ],
       [ 92653, 3.1, 5, 4.1, $leftmost, 6.5, 3, 9.2, $leftmost ],
       [ 58979, 3.1, 5, 4.1, $leftmost, 5.8, 9, 9.7, $leftmost ],
       [ 32384, 3.1, 5, 3.2, 4,         3.8, 5, 4.1, $leftmost,
                5.8, 9, 9.7, $leftmost ],
       [ 62643, 3.1, 5, 3.2, 4,         3.8, 5, 4.1, $leftmost,
                5.8, 9, 6.2, 3,         6.4, 9, 9.7, $leftmost ],
       [ 38327, 3.1, 5, 3.2, 7,         3.8, 5, 4.1, $leftmost,
                5.8, 9, 6.2, 3,         6.4, 9, 9.7, $leftmost ],
       [ 95028, 0.2, 8, 9.5, 9,                 9.7, $leftmost ],
       [ 84197, 0.2, 8, 1.9, 7, 8.4, 8, 9.5, 9, 9.7, $leftmost ],
       [ 16939, 0.2, 8, 1.6, 9, 9.3, 8, 9.5, 9, 9.7, $leftmost ],
       [ 93751, 0.2, 8, 1.6, 9,
                7.5, 1, 9.3, 8,         9.5, 9, 9.7, $leftmost ],
       [ "05820", 0.2, 8, 0.5, 0,
                8.2, 1, 9.3, 8,         9.5, 9, 9.7, $leftmost ],
       [ 97494, 0.2, 8, 0.5, 0,         4.9, 4, 9.7, $leftmost ],
       [ 45923, 0.2, 8, 0.5, 0, 4.5, 3, 9.2, 4, 9.7, $leftmost ],
       [ "07816", 0.2, 8, 0.5, 0,
                0.7, 6, 8.1, 3,         9.2, 4, 9.7, $leftmost ],
       [ 40628, 0.2, 8, 0.5, 0,         0.7, 6, 4.0, 8,
                6.2, 6, 8.1, 3,         9.2, 4, 9.7, $leftmost ],
       [ 62089, 0.2, 8, 0.5, 0,         0.7, 6, 0.8, 9,
                6.2, 6, 8.1, 3,         9.2, 4, 9.7, $leftmost ],
       [ 98628, 0.2, 8, 0.5, 0,         0.7, 6, 0.8, 9,
                6.2, 8, 9.8, $leftmost ],
       [ "03482", 0.2, 8, 0.3, 2,         4.8, 9,
                6.2, 8, 9.8, $leftmost ],
       [ 53421, 0.2, 8, 0.3, 2,         4.2, 1, 5.3, 9,
                6.2, 8, 9.8, $leftmost ],
       [ 17067, 0.2, 8, 0.3, 2,
                0.6, 7, 1.7, 2,         4.2, 1, 5.3, 9,
                6.2, 8, 9.8, $leftmost ],
       [ 98214, 0.2, 8, 0.3, 2,         0.6, 7, 1.7, 2,
                2.1, 4, 9.8, $leftmost ],
       [ 80865, 0.2, 8, 0.3, 2,         0.6, 7, 1.7, 2,
                2.1, 4, 8.0, 5, 8.6, 4, 9.8, $leftmost ],
       [ 13282, 0.2, 8, 0.3, 2,         0.6, 7, 1.3, 2,
                2.8, 4, 8.0, 5, 8.6, 4, 9.8, $leftmost ],
       ## NB: the change is no-op
       [ 30664, 0.2, 8, 0.3, 2,         0.6, 7, 1.3, 2,
                2.8, 4, 8.0, 5, 8.6, 4, 9.8, $leftmost ],
       [ 70938, 0.2, 8, 0.3, 2,         0.6, 7, 1.3, 2,
                2.8, 4, 7.0, 8, 9.3, 4, 9.8, $leftmost ],
       [ 44609, 0.2, 8, 0.3, 2,         0.6, 7, 1.3, 2,
                2.8, 4, 4.4, 9,
                6.0, 4, 7.0, 8, 9.3, 4, 9.8, $leftmost ]);

my @range_tests
    = map {
          my @a
              = split ("", $_->[0]);
          my ($a, $b, $v)
              = ($a[0] + .1 * $a[1],
                 $a[2] + .1 * $a[3], $a[4]);
          ## .
          ($a   < $b ? ([ $a, $b, $v, $_ ])
           : $a > $b ? ([ $b, $a, $v, $_ ])
           : ());
      } (@range_tests_1);

foreach my $r (@range_tests) {
    my ($l, $u, $v, $x)
        = @$r;
    $rat->range_set ($l, $u, $v);
    is_deeply ([ $x->[0], rat_kv () ], $x,
               ("proper backend data after change id " . $x->[0]))
        or diag ("... after range_set (", join (", ", $l, $u, $v), ")");
}

## Local variables:
## indent-tabs-mode: nil
## End:
### 20-rb-num.t ends here
