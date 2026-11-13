use strict;
use Test::More 0.98;
use utf8;

use Text::ANSI::Fold qw(ansi_fold);

# Control sequences other than SGR (cursor movement and the like) have
# no width: the movement of the cursor is not taken into account.

sub width { (ansi_fold($_[0], -1))[2] }

is(width("abc\e[3Ddef"),      6, "CUB has no width");
is(width("abc\e[10Cdef"),     6, "CUF has no width");
is(width("\e[2J\e[1;1Habc"),  3, "ED and CUP have no width");
is(width("\e[?25labc\e[?25h"), 3, "private parameter has no width");
is(width("\x9b3Dabc"),        3, "8-bit CSI has no width");

# spaces put first and moved back over: the image of iTerm2 inline
# image protocol is drawn there
is(width((" " x 21) . "\e[21D" . "\e]1337;File=inline=1:QUJD\a"), 21,
   "spaces moved back over");

my($folded, $rest, $w) = ansi_fold("abc\e[3Ddefghi", 6);
is($folded, "abc\e[3Ddef", "CUB is kept in the folded text");
is($rest,   "ghi",          "the rest after CUB");
is($w,      6,              "width of the folded text with CUB");

# at the folding point, CSI goes with the text after it, as color does
($folded, $rest) = ansi_fold("abc\e[3Dx", 3);
is($folded, "abc",     "CUB at the folding point is not in the former");
is($rest,   "\e[3Dx", "CUB at the folding point goes with the latter");

($folded, $rest) = ansi_fold("abc\e[3D", 10);
is($folded, "abc\e[3D", "CUB at the end is kept");
is($rest,   "",          "nothing remains after CUB at the end");

($folded, $rest) = ansi_fold("\e[31mabc\e[3Ddef\e[m", 4);
is($folded, "\e[31mabc\e[3Dd\e[m", "CUB in colored text");
is($rest,   "\e[31mef\e[m",        "color is recovered after CUB");

done_testing;
