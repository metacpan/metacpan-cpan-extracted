use strict;
use warnings;

use Test::Mock::LWP::Dispatch;
use HTTP::Response;
use FindBin qw( $Bin );
use File::Slurp qw( read_file );

use Test::More tests => 15;
use Test::Deep;

BEGIN { use_ok 'WWW::Discogs' }

my $rt = read_file("$Bin/../requests/master.res");
my $response = HTTP::Response->parse($rt);
$mock_ua->map('http://api.discogs.com/master/23992', $response);

my $client = new_ok('WWW::Discogs' => [], '$client');
my $master = $client->master(id => 23992);
isa_ok($master, 'WWW::Discogs::Master', '$master');
isa_ok($master, 'WWW::Discogs::HasMedia', '$master');
isa_ok($master, 'WWW::Discogs::ReleaseBase', '$master');

is($master->id, 23992, 'id');
is($master->main_release, 830189, 'main_release');

my @versions = $master->versions;
for (@versions) {
    if ($_->{id} == 830189) {
        cmp_deeply($_,
                  {
                      country  => 'Germany',
                      status   => 'Accepted',
                      released => '2006-10-06',
                      thumb    => ignore(),
                      format   => 'CD, Album',
                      id       => 830189,
                      title    => 'The Last Resort',
                      label    => 'Poker Flat Recordings, Rough Trade Arvato',
                      catno    => 'PFRCD18, RTD 586.1018.2'
                  }, 'versions');
    }
}

my @images = $master->images(type => 'primary');
cmp_deeply(\@images, bag({
            uri150 => ignore(),
            width  => 600,
            type   => 'primary',
            height => 600,
            uri    => 'http://api.discogs.com/image/R-830189-1265162680.jpeg'
          }), 'images');

is($master->year, 2006, 'year');

my @styles = $master->styles;
cmp_deeply(\@styles, bag(
                         'Techno',
                         'IDM',
                         'Post Rock',
                         'Tech House',
                         'Ambient',
                         'Minimal' ), 'styles');

my @genres = $master->genres;
cmp_deeply(\@genres, bag('Electronic', 'Rock'), 'genres');

my @artists = $master->artists;
cmp_deeply(\@artists, bag({
            tracks => '',
            name   => "Trentem\x{f8}ller",
            anv    => '',
            role   => '',
            join   => '',
          }), 'artists');

my @extraartists = $master->extraartists;
cmp_deeply(\@extraartists, bag(), 'extraartists');

for ($master->tracklist) {
    if($_->{position} == 1) {
        cmp_deeply($_, {
                           position     => 1,
                           title        => 'Take Me Into Your Skin',
                           duration     => '7:44',
                           extraartists => ignore(),
                       }, 'tracklist');
    }
}
