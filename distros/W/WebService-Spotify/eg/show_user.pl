use strict;
use warnings;
use WebService::Spotify;
use Data::Dumper;

my $username = $ARGV[0] || 'nicklangridge';

my $sp = WebService::Spotify->new;
my $user = $sp->user($username);
print Dumper $user;