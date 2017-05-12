use strict;
use warnings;
use WebService::Spotify;
use WebService::Spotify::Util;

my $username = $ARGV[0];

unless ($username) {
  print "Usage: $0 username";
  exit;
}

my $token = WebService::Spotify::Util::prompt_for_user_token($username);

if ($token) {
  my $sp = WebService::Spotify->new(auth => $token);
  my $playlists = $sp->user_playlists($username);
  print "$_->{name}\n" for @{ $playlists->{items} };
} else {
  print "Can't get token for $username\n";
}