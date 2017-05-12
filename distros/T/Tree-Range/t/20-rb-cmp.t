### 20-rb-cmp.t --- Test cmp-based Tree::Range::RB  -*- Perl -*-

use strict;
use warnings;

use Test::More qw (tests 30);

require_ok ("Tree::Range::RB");

sub cmp {
    ## .
    $_[0] cmp $_[1];
}

my ($cmp, $leftmost)
    = (\&cmp, [ "*leftmost*" ]);
my $rat_options = {
    "cmp"       => $cmp,
    "leftmost"  => $leftmost
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

is_deeply ([ $rat->get_range ("cherry") ],
           [ $leftmost ],
           "unbounded range retrieved from the still empty range tree");

ok ($rat->range_free_p ("almond", "strawberry"),
    "range (almond to strawberry) is free in the still empty range tree");

## NB: creating the iterators early to check their deferred lookup
my ($ic_asc, $ic_dsc)
    = ($rat->range_iter_closure (),
       $rat->range_iter_closure (undef, 1));
isa_ok ($ic_asc, "CODE",
        "ascending keys iterator");
isa_ok ($ic_dsc, "CODE",
        "descending keys iterator");

foreach my $r ("apple, strawberry, 1",
               "banana, cherry, 2",
               "appricot, blackcurrant, 3") {
    my ($l, $u, $v)
        = split (/, */, $r, 3);
    my $prev
        = $rat->get_range ($u);
    $rat->range_set ($l, $u, $v);
    my ($lv, $uv)
        = (scalar ($rat->get_range ($l)),
           scalar ($rat->get_range ($u)));
    is ($lv, $v,
        ("new value retrieved"
         . " after range_set (" . $r . ")"))
        or diag ("tried to set ", $l, " .. ", $u, " to ", $v,
                 " but retrieved ", $lv, " at ", $l, " instead");
    is ($uv, $prev,
        ("old value retrieved from the adjacent range"
         . " after range_set (" . $r . ")"));
}

ok (! $rat->range_free_p ("almond", "strawberry"),
    "range (almond to strawberry) is now not free");
ok (! $rat->range_free_p ("sloe", "tomatillo"),
    "range (sloe to tomatillo) is also occupied");
ok ($rat->range_free_p ("almond", "apple"),
    "range (almond to apple) is still free, however");

my ($min_node, $max_node)
    = ($rat->min_node (),
       $rat->max_node ());
subtest "inspecting minimum and maximum backend nodes"
    =>  sub {
            plan ("tests" => 8);
            can_ok ($min_node,
                    qw (key val successor predecessor));
            can_ok ($max_node,
                    qw (key val successor predecessor));
            is ($min_node->key (), "apple",
                "minimum node key");
            is ($min_node->val (), "1",
                "minimum node value");
            is ($min_node->predecessor (), undef,
                "minimum node has no predecessor");
            is ($max_node->key (), "strawberry",
                "maximum node key");
            is ($max_node->val (), $leftmost,
                "maximum node value");
            is ($max_node->successor (), undef,
                "maximum node has no successor");
        };

my @tree_keys;
## NB: accessing Tree::RB->iter () directly
my $iter
    = $rat->backend ()->iter ();
while (my $node = $iter->next ()) {
    push (@tree_keys, $node->key ());
}
## NB: banana is removed in the process
is_deeply (\@tree_keys,
           [ qw (apple appricot blackcurrant),
             qw (cherry strawberry) ],
           "tree has all the expected keys")
    or diag ("the tree keys are: ",
             join (", ", @tree_keys));

my $ranges = {
    "almond"    => [ $leftmost, undef,  "apple" ],
    "apple"         => [ qw (1  apple    appricot) ],
    "appricot"      => [ qw (3  appricot blackcurrant) ],
    "banana"        => [ qw (3  appricot blackcurrant) ],
    "blackcurrant"  => [ qw (2  blackcurrant cherry) ],
    "blueberry"     => [ qw (2  blackcurrant cherry) ],
    "cherry"        => [ qw (1  cherry   strawberry) ],
    "mango"         => [ qw (1  cherry   strawberry) ],
    "strawberry"  => [ $leftmost, "strawberry" ]
};
foreach my $k (sort { $a cmp $b } (keys (%$ranges))) {
    my @got
        = $rat->get_range ($k);
    is_deeply (\@got,
               $ranges->{$k},
               ("the value and the range for the " . $k . " key"))
        or diag ("got: ", join (", ", @got),
                 " vs. expected: ", join (", ", @{$ranges->{$k}}));
}

subtest "iterating over the ranges"
    =>  sub {
            plan ("tests" => 25);
            my @ranges_asc
                = @{$ranges}{(qw (almond apple appricot),
                              qw (blackcurrant cherry strawberry))};
            my @ranges_dsc
                = reverse (@ranges_asc);

            is_deeply ([ $ic_asc->() ], $_)
                foreach (@ranges_asc);
            is_deeply ([ $ic_asc->() ], [],
                       "ascending iterator is now empty");
            is_deeply ([ $ic_dsc->() ], $_)
                foreach (@ranges_dsc);
            is_deeply ([ $ic_dsc->() ], [],
                       "descending iterator is now empty");

            my $ic_part_asc
                = $rat->range_iter_closure ("blackcurrant");
            isa_ok ($ic_part_asc, "CODE",
                    "partial ascending keys iterator");
            is_deeply ([ $ic_part_asc->() ], $_)
                foreach (@ranges_asc[3 .. 5]);
            is_deeply ([ $ic_part_asc->() ], [],
                       "partial ascending iterator is now empty");

            my $ic_part_dsc
                = $rat->range_iter_closure ("blackcurrant", 1);
            isa_ok ($ic_part_dsc, "CODE",
                    "partial descending keys iterator");
            is_deeply ([ $ic_part_dsc->() ], $_)
                foreach (@ranges_dsc[2 .. 5]);
            is_deeply ([ $ic_part_dsc->() ], [],
                       "partial descending iterator is now empty");
        };

## Local variables:
## indent-tabs-mode: nil
## End:
### 20-rb-cmp.t ends here
