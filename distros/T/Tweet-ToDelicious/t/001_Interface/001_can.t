use v5.14;
use warnings;
use Test::More tests => 1;
use Tweet::ToDelicious::Entity::Interface;

my @method = qw/
    text
    screen_name
    urls
    tags
    posts
    in_reply_to_screen_name
    /;

can_ok 'Tweet::ToDelicious::Entity::Interface', @method;
