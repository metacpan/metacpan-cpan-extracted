use strict;
use Test::More tests => 14;

use WWW::Baseball::NPB;

{
    local $^W = 0;
    *LWP::Simple::get = sub ($) {
	local $/;
	require FileHandle;
	my $handle = FileHandle->new("t/20020331-live.html");
	return <$handle>;
    };
}

my $baseball = WWW::Baseball::NPB->new;

{
    my @games = $baseball->games;
    is @games, 6;

    isa_ok $_, 'WWW::Baseball::NPB::Game' for @games;

    my $game = $games[3];
    is $game->league, 'pacific';
    is $game->home, '近鉄';
    is $game->visitor, 'オリックス';
    is $game->score('近鉄'), 0;
    is $game->score('オリックス'), 0;
    is $game->status, '1回裏';
    is $game->stadium, '大阪ドーム';
}



