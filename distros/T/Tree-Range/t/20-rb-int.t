### 20-rb-int.t --- Test integer-based Tree::Range::RB  -*- Perl -*-

use strict;
use warnings;

use Test::More qw (tests 32);

use integer;

require_ok ("Tree::Range::RB");

sub ncmp {
    ## .
    $_[0] <=> $_[1];
}

my ($cmp, $leftmost)
    = (\&ncmp, "-");
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

is_deeply ([ $rat->get_range (42) ],
           [ $leftmost ],
           "unbounded range retrieved from the still empty range tree");

my $range_test_vec
    = (   "324 3F6 A88 85A 308 D31 319 8A2 E03 707 344 A40 938"
       . " 222 99F 31D 008 2EF A98 EC4 E6C 894 528 21E 638 D01"
       . " 377 BE5 466");

my @range_tests
    = map {
          my @a
              = split ("");
          my ($a, $b, $v)
              = (oct ("0x" . $a[0]), oct ("0x" . $a[1]), $a[2]);
          ## .
          ($a   < $b ? ([ $a, $b, $v ])
           : $a > $b ? ([ $b, $a, $v ])
           : ());
      } (split (/ /, $range_test_vec));

my ($min, $max);
foreach my $r (@range_tests) {
    my ($l, $u, $v)
        = @$r;
    $min
        = $l
        if (! defined ($min) || $l < $min);
    $max
        = $u
        if (! defined ($max) || $u > $max);
}
my $off
    = (-2 + $min);
my $len
    = (+3 + $max - $off);
my @keys
    = ($off .. (-1 + $off + $len));
my @ary
    = (($leftmost) x $len);

sub ary_set {
    my ($l, $u, $v) = @_;
    ## .
    @ary[($l - $off) .. (-1 + $u - $off)]
        = (($v) x (1 + $u - $l));
}

sub ary_str {
    ## .
    join ("", @ary);
}

sub rat_str {
    ## .
    join ("", map { scalar ($rat->get_range ($_)) } (@keys));
}

foreach my $r (@range_tests) {
    my ($l, $u, $v)
        = @$r;
    $rat->range_set ($l, $u, $v);
    ary_set ($l, $u, $v);
    is (rat_str (), ary_str (),
        "range tree data (subset) matches that of an array")
        or diag ("... after range_set (", join (", ", @$r), ")");
}

## Local variables:
## indent-tabs-mode: nil
## End:
### 20-rb-int.t ends here
