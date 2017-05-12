use strict;
use warnings;
use utf8;
use Test::More tests => 7;
BEGIN { use_ok('Text::VisualWidth::PP') };

ok( Text::VisualWidth::PP::width("123abcあいうｱｲｳ") == 15, 'PP width');
ok( Text::VisualWidth::PP::width("0") == 1, 'UTF width string zero');
ok( Text::VisualWidth::PP::width("") == 0, 'UTF width empty string');
ok( Text::VisualWidth::PP::trim("123ｱｲｳあいう",8) eq '123ｱｲｳあ', 'PP trim');
ok( Text::VisualWidth::PP::trim("0",8) eq '0', 'PP trim string zero');
ok( Text::VisualWidth::PP::trim("",8) eq '', 'PP trim empty string');

