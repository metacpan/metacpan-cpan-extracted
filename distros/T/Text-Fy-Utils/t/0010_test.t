use strict;
use warnings;

use Test::More tests => 14;

use_ok('Text::Fy::Utils', qw(
  asciify isoify simplify commify
  cv_from_win cv_to_win
));

my $r = "\x{89}\x{8a}\x{8c}\x{8e}\x{91}\x{92}\x{93}\x{9f}\x{a0}\x{a1}\x{a2}".
        "\x{a5}\x{bc}\x{bd}\x{be}\x{bf}\x{c6}\x{c7}\x{c8}\x{cf}\x{ff}";

my $t = "Ab".$r."\x{172}\x{173}\x{174}\x{178}\x{388}\x{389}\x{38a}\x{3b1}\x{3b2}\x{3b3}";

my $v = "\x{9f}\x{178}\x{ff}\x{8a}\x{160}\x{ea}";

is(Text::Fy::Utils::_aconvert($t, 0, 0), q~Ab?S?Z''"Y?????????CEIyUuW~."Y"     .q~??????~, 'aconvert([ pure ])');
is(Text::Fy::Utils::_aconvert($t, 0, 1), q~Ab?S?Z???Y?????????CEIyUuW~."Y"     .q~??????~, 'aconvert([ pure, win ])');
is(Text::Fy::Utils::_aconvert($t, 1, 0), q~Ab~.$r              .q~UuW~."Y"     .q~??????~, 'aconvert([ iso ])');
is(Text::Fy::Utils::_aconvert($t, 1, 1), q~Ab~.$r              .q~UuW~."\x{9f}".q~??????~, 'aconvert([ iso, win ])');
is(Text::Fy::Utils::_aconvert($t, 2, 0), q~Ab%SOZ''"Y?!cY????ACEIyUuW~."Y"     .q~??????~, 'aconvert([ brutal ])');
is(Text::Fy::Utils::_aconvert($t, 2, 1), q~Ab%SOZ???Y?!cY????ACEIyUuW~."Y"     .q~??????~, 'aconvert([ brutal, win ])');

is(asciify($t),  q~Ab?S?Z''"Y?????????CEIyUuW~."Y".q~??????~, 'asciify');
is(isoify($t),   q~Ab~.$r              .q~UuW~."Y".q~??????~, 'isoify');
is(simplify($t), q~Ab%SOZ''"Y?!cY????ACEIyUuW~."Y".q~??????~, 'simplify');

is(cv_from_win($v), "\x{178}\x{178}\x{ff}\x{160}\x{160}\x{ea}", 'cv_from_win');
is(cv_to_win($v)  , "\x{9f}\x{9f}\x{ff}\x{8a}\x{8a}\x{ea}",     'cv_to_win');

is(commify('23456789.12'),      '23_456_789.12', 'commify simple');
is(commify('23456789.12', ','), '23,456,789.12', 'commify variable');
