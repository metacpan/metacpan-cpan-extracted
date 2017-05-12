use strict;
use Test::More (tests => 2);

BEGIN
{
    use_ok("Text::MeCab");
}

can_ok("Text::MeCab::Node", 
    qw(id surface feature length prev next stat cost),
    qw(rlength rcattr lcattr posid char_type isbest alpha beta prob wcost)
);
