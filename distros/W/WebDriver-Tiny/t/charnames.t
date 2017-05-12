use strict;
use warnings;

use Test::More tests => 114;

require charnames;
require WebDriver::Tiny;

my %chars = (
    WD_NULL            => 57344, WD_CANCEL     => 57345,
    WD_HELP            => 57346, WD_BACK_SPACE => 57347,
    WD_TAB             => 57348, WD_CLEAR      => 57349,
    WD_RETURN          => 57350, WD_ENTER      => 57351,
    WD_SHIFT           => 57352, WD_CONTROL    => 57353,
    WD_ALT             => 57354, WD_PAUSE      => 57355,
    WD_ESCAPE          => 57356, WD_SPACE      => 57357,
    WD_PAGE_UP         => 57358, WD_PAGE_DOWN  => 57359,
    WD_END             => 57360, WD_HOME       => 57361,
    WD_ARROW_LEFT      => 57362, WD_ARROW_UP   => 57363,
    WD_ARROW_RIGHT     => 57364, WD_ARROW_DOWN => 57365,
    WD_INSERT          => 57366, WD_DELETE     => 57367,
    WD_SEMICOLON       => 57368, WD_EQUALS     => 57369,
    WD_NUMPAD0         => 57370, WD_NUMPAD1    => 57371,
    WD_NUMPAD2         => 57372, WD_NUMPAD3    => 57373,
    WD_NUMPAD4         => 57374, WD_NUMPAD5    => 57375,
    WD_NUMPAD6         => 57376, WD_NUMPAD7    => 57377,
    WD_NUMPAD8         => 57378, WD_NUMPAD9    => 57379,
    WD_MULTIPLY        => 57380, WD_ADD        => 57381,
    WD_SEPARATOR       => 57382, WD_SUBTRACT   => 57383,
    WD_DECIMAL         => 57384, WD_DIVIDE     => 57385,
    WD_F1              => 57393, WD_F2         => 57394,
    WD_F3              => 57395, WD_F4         => 57396,
    WD_F5              => 57397, WD_F6         => 57398,
    WD_F7              => 57399, WD_F8         => 57400,
    WD_F9              => 57401, WD_F10        => 57402,
    WD_F11             => 57403, WD_F12        => 57404,
    WD_META            => 57405, WD_COMMAND    => 57405,
    WD_ZENKAKU_HANKAKU => 57408,
);

is charnames::vianame($_), undef, "$_ isn't imported" for sort keys %chars;

{
    use WebDriver::Tiny;

    is charnames::vianame($_), $chars{$_}, "$_ is imported"
        for sort keys %chars;
}
