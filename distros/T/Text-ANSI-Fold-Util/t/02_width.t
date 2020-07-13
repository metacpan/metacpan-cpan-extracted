use strict;
use Test::More 0.98;

use Text::ANSI::Fold::Util qw(ansi_width);

$_ = "111222333";

is(ansi_width($_), 9, "ansi_width");

$_ = "\e[31m111222333\e[m";

is(ansi_width($_), 9, "ansi_width: color");

done_testing;

