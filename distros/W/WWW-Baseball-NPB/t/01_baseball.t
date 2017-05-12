use strict;
use Test::More tests => 25;

use WWW::Baseball::NPB;

{
    local $^W = 0;
    *LWP::Simple::get = sub ($) {
	local $/;
	require FileHandle;
	my $handle = FileHandle->new("t/20020330.html");
	return <$handle>;
    };
}

my $baseball = WWW::Baseball::NPB->new;

{
    my @games = $baseball->games;
    is @games, 6;

    isa_ok $_, 'WWW::Baseball::NPB::Game' for @games;

    my $game = $games[0];
    is $game->league, 'central';
    is $game->home, '巨人';
    is $game->visitor, '阪神';
    is $game->score('巨人'), 1;
    is $game->score('阪神'), 3;
    is $game->status, '終了';
    is $game->stadium, '東京ドーム';
}

{
    my @games = $baseball->games('pacific');
    is @games, 3;

    isa_ok $_, 'WWW::Baseball::NPB::Game' for @games;

    my $game = $games[0];
    is $game->league, 'pacific';
    is $game->home, '近鉄';
    is $game->visitor, 'オリックス';
    is $game->score('近鉄'), 6;
    is $game->score('オリックス'), 3;
    is $game->status, '終了';
    is $game->stadium, '大阪ドーム';
}



