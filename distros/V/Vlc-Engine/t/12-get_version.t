use strict;
use warnings;

use Test::More tests => 1;
use Vlc::Engine;

my $player = Vlc::Engine->new;

my ($version);
eval { $version = $player->vlc_version(); };
is($@, '', 'plain: $version: vlc_version() returned scalar');

