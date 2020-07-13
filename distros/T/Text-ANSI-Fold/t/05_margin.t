use strict;
use Test::More 0.98;
use utf8;
use open IO => 'utf8', ':std';

use Text::ANSI::Fold ':constants';

my $fold;

sub folded {
    my($folded, $rest) = $fold->fold(@_);
    $folded;
}

$fold = Text::ANSI::Fold->new(
    linebreak => LINEBREAK_ALL,
    );

$_ = "「吾輩は猫である。」「（名前は）まだない。」";
is(folded($_, width => 14), "「吾輩は猫であ",             "normal");
is(folded($_, width => 16), "「吾輩は猫である。",         "normal");
is(folded($_, width => 18), "「吾輩は猫である。」",       "run-in(2)");
is(folded($_, width => 20), "「吾輩は猫である。」",       "normal");
is(folded($_, width => 22), "「吾輩は猫である。」",       "run-out(2)");
is(folded($_, width => 24), "「吾輩は猫である。」「（",   "normal");
is(folded($_, width => 26), "「吾輩は猫である。」「（名", "normal");

$fold->configure(margin => 0);
is(folded($_, width => 14), "「吾輩は猫であ",             "normal");
is(folded($_, width => 16), "「吾輩は猫である。",         "normal");
is(folded($_, width => 18), "「吾輩は猫である。」",       "run-in(2)");
is(folded($_, width => 20), "「吾輩は猫である。」",       "normal");
is(folded($_, width => 22), "「吾輩は猫である。」",       "run-out(2)");
is(folded($_, width => 24), "「吾輩は猫である。」「（",   "normal");
is(folded($_, width => 26), "「吾輩は猫である。」「（名", "normal");

$fold->configure(margin => 4);
is(folded($_, width => 18), "「吾輩は猫であ",             "normal");
is(folded($_, width => 20), "「吾輩は猫である。",         "normal");
is(folded($_, width => 22), "「吾輩は猫である。」",       "run-in(2)");
is(folded($_, width => 24), "「吾輩は猫である。」",       "normal");
is(folded($_, width => 26), "「吾輩は猫である。」",       "run-out(2)");
is(folded($_, width => 28), "「吾輩は猫である。」「（",   "normal");
is(folded($_, width => 30), "「吾輩は猫である。」「（名", "normal");

$fold->configure(runin => 4, runout => 4);
$_ = "「吾輩は猫である。」「（名前は）まだない。」";
is(folded($_, width => 18), "「吾輩は猫であ",             "[4]normal");
is(folded($_, width => 20), "「吾輩は猫である。」",       "[4]run-in(2)");
is(folded($_, width => 22), "「吾輩は猫である。」",       "[4]nun-in(4)");
is(folded($_, width => 24), "「吾輩は猫である。」",       "[4]normal");
is(folded($_, width => 26), "「吾輩は猫である。」",       "[4]run-out(2)");
is(folded($_, width => 28), "「吾輩は猫である。」",       "[4]run-out(4)");
is(folded($_, width => 30), "「吾輩は猫である。」「（名", "[4]normal");

$fold->configure(padding => 1);
$_ = "「吾輩は猫である。」「（名前は）まだない。」";
is(folded($_, width => 18), "「吾輩は猫であ    ",             "[4]normal");
is(folded($_, width => 20), "「吾輩は猫である。」",       "[4]run-in(2)");
is(folded($_, width => 22), "「吾輩は猫である。」  ",       "[4]nun-in(4)");
is(folded($_, width => 24), "「吾輩は猫である。」    ",       "[4]normal");
is(folded($_, width => 26), "「吾輩は猫である。」      ",       "[4]run-out(2)");
is(folded($_, width => 28), "「吾輩は猫である。」        ",       "[4]run-out(4)");
is(folded($_, width => 30), "「吾輩は猫である。」「（名    ", "[4]normal");

done_testing;
