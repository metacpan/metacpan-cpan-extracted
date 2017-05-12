use strict;
use warnings;
use Data::Dumper;
use WebService::Spotify;
use WebService::Spotify::Util;

my ($username, $playlist_name) = @ARGV;

unless ($username and $playlist_name) {
  print "Usage: $0 username playlist_name\n";
  exit;
}

my $token = WebService::Spotify::Util::prompt_for_user_token($username);

if ($token) {
  my $sp = WebService::Spotify->new(auth => $token);
  my $playlists = $sp->user_playlist_create($username, $playlist_name);
  print Dumper $playlists;
} else {
  print "Can't get token for $username\n";
}