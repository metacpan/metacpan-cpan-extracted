### 30-range.t --- Check Tree::Range  -*- Perl -*-

use strict;
use warnings;

use Test::More  qw (tests 5);

require_ok ("Tree::Range");
require_ok ("Tree::Range::RB");
require_ok ("Tree::Range::RB::Conflict");

sub cmp {
    ## .
    $_[0] cmp $_[1];
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

sub check_var {
    my ($class_sfx) = @_;
    plan ("tests" => 6);
    my $rat
        = Tree::Range->new ($class_sfx, $rat_options);
    isa_ok ($rat, ("Tree::Range::" . $class_sfx),
            "RB-based range tree");
    isa_ok ($rat->backend (), "Tree::RB",
            "associated backend tree object");
    is ($rat->cmp_fn (), $cmp,
        "associated comparison function");
    is ($rat->value_equal_p_fn (), $value_equal_p,
        "associated value equality predicate");
    is ($rat->leftmost_value (), $leftmost,
        "associated leftmost value");
    my $conflict_p
        = ($class_sfx =~ /::Conflict/i);
    cmp_ok ($rat->can ("range_set"),
            ($conflict_p ? "ne" : "eq"),
            $rat->can ("range_set_over"),
            ("->range_set () "
             . ($conflict_p ? "is not" : "is")
             . " an alias to ->range_set_over ()"));
}

subtest (("creating a Tree::Range::"
             . $_ . " instance with Tree::Range->new ()"),
         sub { check_var ($_); })
    foreach (qw (RB RB::Conflict));

## Local variables:
## coding: us-ascii
## End:
### 30-range.t ends here
