use strict;
use open IO => 'utf8', ':std';
use Test::More 0.98;
use utf8;

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

$fold->configure(runin => 4, runout => 4);
$_ = "「吾輩は猫である。」「（名前は）まだない。」";
is(folded($_, width => 14), "「吾輩は猫であ",             "[4]normal");
is(folded($_, width => 16), "「吾輩は猫である。」",       "[4]run-in(2)");
is(folded($_, width => 18), "「吾輩は猫である。」",       "[4]nun-in(4)");
is(folded($_, width => 20), "「吾輩は猫である。」",       "[4]normal");
is(folded($_, width => 22), "「吾輩は猫である。」",       "[4]run-out(2)");
is(folded($_, width => 24), "「吾輩は猫である。」",       "[4]run-out(4)");
is(folded($_, width => 26), "「吾輩は猫である。」「（名", "[4]normal");

sub bd { $_[0] =~ s/(\X)/$1\cH$1/gr }

$fold->configure(runin => 2, runout => 2);
$_ = bd "「吾輩は猫である。」「（名前は）まだない。」";
is(folded($_, width => 14), bd("「吾輩は猫であ"),             "bd normal");
is(folded($_, width => 16), bd("「吾輩は猫である。"),         "bd normal");
is(folded($_, width => 18), bd("「吾輩は猫である。」"),       "bd run-in(2)");
is(folded($_, width => 20), bd("「吾輩は猫である。」"),       "bd normal");
is(folded($_, width => 22), bd("「吾輩は猫である。」"),       "bd run-out(2)");
is(folded($_, width => 24), bd("「吾輩は猫である。」「（"),   "bd normal");
is(folded($_, width => 26), bd("「吾輩は猫である。」「（名"), "bd normal");

$fold->configure(runin => 4, runout => 4);
$_ = bd "「吾輩は猫である。」「（名前は）まだない。」";
is(folded($_, width => 14), bd("「吾輩は猫であ"),             "[4]bd normal");
is(folded($_, width => 16), bd("「吾輩は猫である。」"),       "[4]bd run-in(2)");
is(folded($_, width => 18), bd("「吾輩は猫である。」"),       "[4]bd nun-in(4)");
is(folded($_, width => 20), bd("「吾輩は猫である。」"),       "[4]bd normal");
is(folded($_, width => 22), bd("「吾輩は猫である。」"),       "[4]bd run-out(2)");
is(folded($_, width => 24), bd("「吾輩は猫である。」"),       "[4]bd run-out(4)");
is(folded($_, width => 26), bd("「吾輩は猫である。」「（名"), "[4]bd normal");

# Colors left after the run-in character, with no visible text after
# them, stay on the line and do not make a line of their own.  They
# are not closed here: a color which the text leaves open at its end
# is left open.
{
    my $runin = sub {
	my $f = Text::ANSI::Fold->new(width => 4, linebreak => LINEBREAK_RUNIN);
	[ $f->text(shift)->chops ];
    };
    is_deeply($runin->("\e[31mabcd.\e[0m\e[22;23;24m"),
	      [ "\e[31mabcd.\e[0m\e[22;23;24m" ],
	      "run-in: reset and another sequence at the end");
    is_deeply($runin->("abcd.\e[0m\e[1m"),
	      [ "abcd.\e[0m\e[1m" ],
	      "run-in: reset and color at the end");
    is_deeply($runin->("abcd.\e[1m"),
	      [ "abcd.\e[1m" ],
	      "run-in: color at the end");
    is_deeply($runin->("\e[31mabcd.\e[1m"),
	      [ "\e[31mabcd.\e[1m\e[m" ],
	      "run-in: the color of the line is closed");
    is_deeply($runin->("abcd.\e[1mefgh"),
	      [ "abcd.", "\e[1mefgh\e[m" ],
	      "run-in: color with text after it goes to the next line");
}

done_testing;
