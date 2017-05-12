use strict;
use warnings;
use URI;
use Test::More tests => 10;

BEGIN {
    use_ok 'WWW::KGS::GameArchives::Result::Game';
}

my $game = WWW::KGS::GameArchives::Result::Game->new({
    kifu_uri => URI->new('http://files.gokgs.com/games/2013/7/1/foo-bar.sgf'),
    setup => "19\x{d7}19 H2",
    white => [
        {
            link => URI->new('http://www.gokgs.com/gameArchives.jsp?user=foo'),
            name => 'foo [2k]',
        },
    ],
    black => [
        {
            link => URI->new('http://www.gokgs.com/gameArchives.jsp?user=bar'),
            name => 'bar [4k]',
        },
    ],
    start_time => '7/1/13 5:47 AM',
    type => 'Ranked',
    result => 'Unfinished'
});

ok $game->is_viewable;
is $game->kifu_uri, 'http://files.gokgs.com/games/2013/7/1/foo-bar.sgf';
isa_ok $game->white->[0], 'WWW::KGS::GameArchives::Result::User';
isa_ok $game->black->[0], 'WWW::KGS::GameArchives::Result::User';
is $game->size, 19;
is $game->handicap, 2;
isa_ok $game->start_time, 'Time::Piece';
is $game->type, 'Ranked';
is $game->result, 'Unfinished';
