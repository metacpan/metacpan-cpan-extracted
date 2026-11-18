use strict;
use Test::More 0.98;

use_ok $_ for qw(
    Text::ANSI::Highlight
    Text::ANSI::Highlight::pandoc
    Text::ANSI::Highlight::sourcehighlight
    Text::ANSI::Highlight::skylighting
);

done_testing;
