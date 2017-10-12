use strict;
use warnings;
use utf8;

use Test::More;

unless ($ENV{FILE_MEDIA_TEST}) {
    plan skip_all => 'test requires a media file environment variable';
}
else {
    plan tests => 2;
}

use Vlc::Engine;

my $player = Vlc::Engine->new;
$player->set_media($ENV{FILE_MEDIA_TEST});
$player->parsing_media();

my ($artist, $title);
eval { $artist = $player->get_meta('artist'); };
is($@, '', 'get_meta("artist") returned scalar');

eval { $title = $player->get_meta('title'); };
is($@, '', 'get_meta("title") returned scalar');
