use strict;
use warnings;

use Test::Mock::LWP::Dispatch;
use HTTP::Response;
use FindBin qw( $Bin );
use File::Slurp qw( read_file );

use Test::More tests => 22;

BEGIN { use_ok 'WWW::Discogs' }

my $rt = read_file("$Bin/../requests/release.res");
my $response = HTTP::Response->parse($rt);
$mock_ua->map('http://api.discogs.com/release/1', $response);

my $client = new_ok('WWW::Discogs' => [], '$client');
my $rel = $client->release(id => 1);
isa_ok($rel, 'WWW::Discogs::Release','$rel');
isa_ok($rel, 'WWW::Discogs::HasMedia', '$rel');
isa_ok($rel, 'WWW::Discogs::ReleaseBase', '$rel');

is($rel->country, 'Sweden', 'country');
is($rel->title, 'Stockholm', 'title');
is($rel->released, "1999-03-00", 'released');
is($rel->released_formatted, 'Mar 1999', 'released_formatted');
is($rel->id, 1, 'id');
is($rel->status, 'Accepted', 'status');
like($rel->notes, qr/^Recorded at the Globe studio in Stockholm/, 'notes');
is($rel->year, 1999, 'year');
is($rel->master_id, 5427, 'master_id');
is_deeply($rel->styles, 'Deep House', 'style');
is_deeply($rel->formats,
          {
              descriptions => [ '12"' ],
              name         => 'Vinyl',
              qty          => 2,
          }, 'format');

is_deeply($rel->genres, 'Electronic', 'genres');
is_deeply($rel->labels,
          {
              name        => 'Svek',
              catno       => 'SK032',
              entity_type => 1,
          }, 'labels');

for ($rel->tracklist) {
    if ($_->{position} eq "B1") {
        is_deeply($_,
                  {
                      position => 'B1',
                      title    => 'Vasastaden',
                      duration => '6:11',
                  }, 'tracklist');
    }
}

is_deeply($rel->artists,
          {
              tracks => '',
              name   => 'Persuader, The',
              anv    => '',
              role   => '',
              join   => '',
          }, 'artists');

is_deeply($rel->extraartists,
          {
              tracks => '',
              name   => "Jesper Dahlb\x{e4}ck",
              anv    => '',
              role   => 'Music By [All Tracks By]',
              join   => '',
          }, 'extraartists');

my @images = $rel->images(type => 'primary');
is($images[0]->{uri},
   'http://api.discogs.com/image/R-1-1193812031.jpeg',
   'images'
);
