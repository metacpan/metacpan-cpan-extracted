use strict;
use warnings;
use utf8;
use Test::More;

use Text::MatchedPosition;

# ascii
{
    my $text = <<'_TEXT_';
01234567890
abcdefghijklmn
opqrstuvwxyz
_TEXT_

    my $regex = qr/jk/;

    my $pos = Text::MatchedPosition->new(\$text, $regex);
    isa_ok $pos, 'Text::MatchedPosition', 'object';
    is $pos->line, 2, 'line';
    is $pos->offset, 10, 'offset';
}

# ascii: copy text
{
    my $text = <<'_TEXT_';
01234567890
abcdefghijklmn
opqrstuvwxyz
_TEXT_

    my $regex = qr/jk/;

    my $pos = Text::MatchedPosition->new($text, $regex);
    is $pos->line, 2, 'line';
    is $pos->offset, 10, 'offset';
}

# wide char
{
    my $text = <<'_TEXT_';
０１２３４５６７８９
あいうえおかきくけこさしすせそ
たちつてとなにぬねのはひふへほ
_TEXT_

    my $regex = qr/おかき/;

    my $pos = Text::MatchedPosition->new(\$text, $regex);
    is $pos->line, 2, 'line';
    is $pos->offset, 5, 'offset';
}

# no match
{
    my $text = <<'_TEXT_';
01234567890
abcdefghijklmn
opqrstuvwxyz
_TEXT_

    my $regex = qr/jd/;

    my $pos = Text::MatchedPosition->new(\$text, $regex);
    is $pos->line, undef, 'line';
    is $pos->offset, undef, 'offset';
}

# from top
{
    my $text = <<'_TEXT_';
01234567890
abcdefghijklmn
opqrstuvwxyz
_TEXT_

    my $regex = qr/.+/;

    my $pos = Text::MatchedPosition->new(\$text, $regex);
    is $pos->line, 1, 'line';
    is $pos->offset, 1, 'offset';
}

# blank line
{
    my $text = <<'_TEXT_';
0123

jk
_TEXT_

    my $regex = qr/jk/;

    my $pos = Text::MatchedPosition->new(\$text, $regex);
    is $pos->line, 3, 'line';
    is $pos->offset, 1, 'offset';
}

done_testing;
