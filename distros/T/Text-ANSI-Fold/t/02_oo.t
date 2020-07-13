use strict;
use Test::More 0.98;
use utf8;

use Text::ANSI::Fold;

my $fold = Text::ANSI::Fold->new;

sub folded {
    my $obj = shift;
    my($folded, $rest) = $obj->fold(@_);
    $folded;
}

$_ = "12345678901234567890123456789012345678901234567890";
is(folded($fold, $_, width => 10), "1234567890",   "ASCII");
is(folded($fold, $_, width => length), $_,         "ASCII: just");
is(folded($fold, $_, width => length($_) * 2), $_, "ASCII: long");

$_ = "１２３４５６７８９０１２３４５６７８９０１２３４５６７８９０";
is(folded($fold, $_, width => 10), "１２３４５",    "WIDE");
is(folded($fold, $_, width => length($_) * 2), $_, "WIDE: just");
is(folded($fold, $_, width => length($_) * 4), $_, "WIDE: long");

is(folded($fold, $_, width => 9), "１２３４",    "WIDE: one short");
is(folded($fold, $_, width => 11), "１２３４５", "WIDE: one over");

$_ = "aaa bbb cccdddeeefff";
is(folded($fold, $_, width => 5), "aaa b", "boundary: none");
is(folded($fold, $_, width => 6), "aaa bb", "boundary: none");
is(folded($fold, $_, width => 7), "aaa bbb", "boundary: none");

$fold->configure(boundary => 'word');
is(folded($fold, $_, width => 5), "aaa ", "boundary: word");
is(folded($fold, $_, width => 6), "aaa ", "boundary: word");
is(folded($fold, $_, width => 7), "aaa bbb", "boundary: word");
is(folded($fold, $_, width => 9), "aaa bbb c", "boundary: word");


$fold = Text::ANSI::Fold->new(width => 3);
$_ = "●●●●●";
is(folded($fold, $_), "●●●", "Ambiguous");
is(folded($fold, $_, ambiguous => 'wide'), "●", "Ambiguous: WIDE");

$fold = Text::ANSI::Fold->new(
    width => 3,
    ambiguous => 'wide',
    );
$_ = "●●●●●";
is(folded($fold, $_), "●", "Ambiguous: WIDE");

done_testing;
