use Test::Most;
use Data::Dumper;

my $creep_urn       = 'spotify:track:3HfB5hBU0dmBt8T0iCmH42';
my $creep_id        = '3HfB5hBU0dmBt8T0iCmH42';
my $creep_url       = 'http://open.spotify.com/track/3HfB5hBU0dmBt8T0iCmH42';
my $el_scorcho_urn  = 'spotify:track:0Svkvt5I79wficMFgaqEQJ';
my $pinkerton_urn   = 'spotify:album:04xe676vyiTeYNXw15o9jT';
my $weezer_urn      = 'spotify:artist:3jOstUTkEu2JkjvRdBA5Gu';
my $pablo_honey_urn = 'spotify:album:6AZv3m27uyRxi8KyJSfUxL';
my $radiohead_urn   = 'spotify:artist:4Z8W4fKeB5YxbusRsdQVPb';
my $bad_id          = 'BAD_ID';
my $user_id         = 'nicklangridge';

BEGIN { 
  use_ok 'WebService::Spotify';
}

my $spotify = new_ok 'WebService::Spotify';

$spotify->trace(1) if $ARGV[0] =~ /^-t|--trace$/;

# artists

{
  my $result = $spotify->artist($radiohead_urn);
  is $result->{name}, 'Radiohead', 'got artist Radiohead';
}
{
  my $result = $spotify->artists([ $weezer_urn, $radiohead_urn ]);
  isa_ok $result->{artists}, 'ARRAY';
  is @{$result->{artists}}, 2, 'got 2 artists';
}
{
  my $result = $spotify->artist_top_tracks($weezer_urn);
  isa_ok $result->{tracks}, 'ARRAY';
  is @{$result->{tracks}}, 10, 'got 10 top tracks';
}
{
  my $result = $spotify->artist_albums($weezer_urn);
  isa_ok $result->{items}, 'ARRAY';
  ok @{$result->{items}} > 0, 'got some Weezer albums';
  ok((grep {$_->{name} eq 'Hurley'} @{$result->{items}}), 'got album Hurley');
}

# albums

{
  my $result = $spotify->album($pinkerton_urn);
  is $result->{name}, 'Pinkerton', 'got album Pinkerton';
}
{
  my $result = $spotify->album_tracks($pinkerton_urn);
  isa_ok $result->{items}, 'ARRAY';
  is @{$result->{items}}, 10, 'got 10 Pinkerton tracks';
}
{
  my $result = $spotify->albums([ $pinkerton_urn, $pablo_honey_urn ]);
  isa_ok $result->{albums}, 'ARRAY';
  is @{$result->{albums}}, 2, 'got 2 albums';
}


# tracks

{
  my $result = $spotify->track($creep_urn);
  is $result->{name}, 'Creep', 'got track Creep by URN';
}
{
  my $result = $spotify->track($creep_id);
  is $result->{name}, 'Creep', 'got track Creep by ID';
}
{
  my $result = $spotify->track($creep_url);
  is $result->{name}, 'Creep', 'got track Creep by URL';
}
{
  my $result = $spotify->tracks([$creep_url, $el_scorcho_urn]);
  isa_ok $result->{tracks}, 'ARRAY';
  is @{$result->{tracks}}, 2, 'got 2 tracks';
}

# search

{
  my $result = $spotify->search('weezer', type => 'artist');
  isa_ok $result->{artists}, 'HASH';
  isa_ok $result->{artists}->{items}, 'ARRAY';
  ok @{$result->{artists}->{items}} > 0, 'found some artists';
}
{
  my $result = $spotify->search('weezer pinkerton', type => 'album');
  isa_ok $result->{albums}, 'HASH';
  isa_ok $result->{albums}->{items}, 'ARRAY';
  ok $result->{albums}->{items}->[0]->{name} =~ /^Pinkerton/, 'found album Pinkerton';
}
{
  my $result = $spotify->search('el scorcho', type => 'track');
  isa_ok $result->{tracks}, 'HASH';
  isa_ok $result->{tracks}->{items}, 'ARRAY';
  is $result->{tracks}->{items}->[0]->{name}, 'El Scorcho', 'found track El Scorcho';
}

# user

{
  my $result = $spotify->user($user_id);
  is $result->{uri}, "spotify:user:$user_id", 'got user';
}

# exceptions

{
  my $result = $spotify->track($bad_id);
  ok $result->{error}->{message} =~ /invalid id/i, 'invalid id';
}
{
  my $result = $spotify->me;
  ok $result->{error}->{message} =~ /no token provided/i, 'no token provided';
}

done_testing();
