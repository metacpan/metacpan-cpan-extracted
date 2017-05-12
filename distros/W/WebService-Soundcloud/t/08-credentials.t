use strict;
use warnings;

use Test::More;


my $username = $ENV{SC_USERNAME};
my $password = $ENV{SC_PASSWORD};

if (defined $username && defined $password)
{
    plan 'no_plan';
}
else
{
    plan 'skip_all' => 'No $SC_USERNAME or $SC_PASSWORD defined';
}


use_ok('WebService::Soundcloud');

my $client_id = 'I2OBiw2wX09A9EAU5Qx4w';
my $client_secret = 'twr9Wj7Qw16qrChi2lpl4dxTEWix9JuSg8mOgdF52F8';

my $args = {
               redirect_uri => 'http://localhost/soundcloud/connect',
               scope         => 'non-expiring',
               username      => $username,
               password      => $password

           };

ok(my $sc = WebService::Soundcloud->new( $client_id, $client_secret,$args),"new object with credentials");

ok(my $token = $sc->get_access_token(), "get access token - no code needed");
ok(my $me = $sc->get_object('/me'), "get_object - /me");
ok($me->{permalink}, "and the data has something in it");
ok(my $tracks = $sc->get_list('/me/tracks'), 'get_list - "/me/tracks"');
ok(@{$tracks}, "and we got some tracks");
is(@{$tracks}, $me->{track_count}, "and the same as the number on the me");

