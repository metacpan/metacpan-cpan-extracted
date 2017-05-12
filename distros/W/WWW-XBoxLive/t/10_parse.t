#!perl

use strict;
use warnings;

use Test::More tests => 43;

use FindBin qw($Bin);

BEGIN { use_ok('WWW::XBoxLive'); }
require_ok('WWW::XBoxLive');

use WWW::XBoxLive::Gamercard;

my @args = ( { region => 'foo' } );
my $xbox_live = new_ok( 'WWW::XBoxLive', \@args );
is( $xbox_live->{region}, 'foo', 'region' );
$xbox_live = new_ok('WWW::XBoxLive');
is( $xbox_live->{region}, 'en-US', 'region' );

open( my $fh, '<:encoding(UTF-8)', "$Bin/resources/BrazenStraw3.card" )
  or die $!;
my $hold = $/;
undef $/;
my $html = <$fh>;
$/ = $hold;

my $gamercard = $xbox_live->_parse_gamercard($html);
isa_ok( $gamercard, 'WWW::XBoxLive::Gamercard' );

ok( $gamercard->is_valid, 'is_valid' );
is(
    $gamercard->bio,
'Software developer and a bit of a geek. Arsenal fan. http://twitter.com/andrewrjones http://andrew-jones.com',
    'bio'
);
is( $gamercard->account_status, 'gold',            'account_status' );
is( $gamercard->gamerscore,     '150',             'gamerscore' );
is( $gamercard->gamertag,       'BrazenStraw3',    'gamertag' );
is( $gamercard->gender,         'male',            'gender' );
is( $gamercard->location,       'UK',              'location' );
is( $gamercard->motto,          'Am I drunk yet?', 'motto' );
is( $gamercard->name,           'Andrew',          'name' );
is( $gamercard->profile_link,
    'http://live.xbox.com/en-US/MyXbox/Profile?Gamertag=BrazenStraw3',
    'profile_link' );
is( $gamercard->reputation, 3, 'reputation' );

is( scalar @{ $gamercard->recent_games }, 2, '2 recent games' );

my $game = $gamercard->recent_games->[0];
isa_ok( $game, 'WWW::XBoxLive::Game' );
is( $game->available_achievements, 50,   'game 1 available_achievements' );
is( $game->available_gamerscore,   1000, 'game 1 available_gamerscore' );
is( $game->earned_achievements,    2,    'game 1 earned_achievements' );
is( $game->earned_gamerscore,      15,   'game 1 earned_gamerscore' );
is( $game->last_played,         '1/1/2012', 'game 1 last_played' );
is( $game->percentage_complete, '4%',       'game 1 percentage_complete' );
like( $game->title, qr/Modern Warfare/, 'game 1 title' );

$game = $gamercard->recent_games->[1];
isa_ok( $game, 'WWW::XBoxLive::Game' );
is( $game->available_achievements, 45,   'game 2 available_achievements' );
is( $game->available_gamerscore,   1000, 'game 2 available_gamerscore' );
is( $game->earned_achievements,    6,    'game 2 earned_achievements' );
is( $game->earned_gamerscore,      135,  'game 2 earned_gamerscore' );
is( $game->last_played,         '12/31/2011', 'game 2 last_played' );
is( $game->percentage_complete, '13%',        'game 2 percentage_complete' );
is( $game->title,               'FIFA 12',    'game 2 title' );

close $fh;

# female silver gamercard
open( $fh, '<:encoding(UTF-8)', "$Bin/resources/miss.card" )
  or die $!;
$hold = $/;
undef $/;
$html = <$fh>;
$/    = $hold;

$gamercard = $xbox_live->_parse_gamercard($html);
isa_ok( $gamercard, 'WWW::XBoxLive::Gamercard' );

is( $gamercard->account_status, 'silver', 'account_status' );
is( $gamercard->gamertag,       'MISS',   'gamertag' );
is( $gamercard->gender,         'female', 'gender' );
ok( $gamercard->is_valid, 'is_valid' );

close $fh;

# invalid gamercard
open( $fh, '<:encoding(UTF-8)', "$Bin/resources/invalid.card" )
  or die $!;
$hold = $/;
undef $/;
$html = <$fh>;
$/    = $hold;

$gamercard = $xbox_live->_parse_gamercard($html);
isa_ok( $gamercard, 'WWW::XBoxLive::Gamercard' );

is( $gamercard->gamertag, 'skflgnskjdgnsuibfsdgdsgsgdsg', 'gamertag' );
ok( !$gamercard->is_valid, 'is_valid' );

close $fh;
