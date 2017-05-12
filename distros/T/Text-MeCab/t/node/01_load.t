use strict;
use Test::More (tests => 2);

BEGIN
{
    use_ok("Text::MeCab");
}

can_ok("Text::MeCab::Node", "next");