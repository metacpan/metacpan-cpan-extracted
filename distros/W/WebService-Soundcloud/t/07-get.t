#!/usr/bin/perl
use Test::More qw(no_plan);
# Load the WebService::Soundcloud module
BEGIN { use_ok('WebService::Soundcloud') }
require_ok('WebService::Soundcloud');
# Create a constuctor
my $scloud = WebService::Soundcloud->new(
    'I2OBiw2wX09A9EAU5Qx4w',
    'twr9Wj7Qw16qrChi2lpl4dxTEWix9JuSg8mOgdF52F8',
    {
        redirect_uri    => 'http://localhost/callback',
        debug           => 0,
    }
);

isa_ok( $scloud, "WebService::Soundcloud" );
# coverage for response_format and request_format subroutines
my $res_format = 'xml';
my $req_format = 'xml';
# default should be set to 'json', get response_format test
ok( defined( $scloud->response_format() ), "response_format is defined." );
is($scloud->response_format(), 'json', 'and has the correct default');
# default should be set to 'json', get request_format test
ok( defined( $scloud->request_format() ), "request_format is defined." );
is($scloud->request_format(), 'json', 'and has the correct default');
# set response_format test
ok(
    $res_format eq $scloud->response_format($res_format),
    'Accept header element set/get works through response_format!'
);
# set request_format test
ok( $req_format eq $scloud->request_format($req_format),
    'Content-Type header element set/get works through request_format!' );
# test get_authorization_url
my $url = 'https://api.soundcloud.com/connect?response_type=code&redirect_uri=http%3A%2F%2Flocalhost%2Fcallback&client_id=I2OBiw2wX09A9EAU5Qx4w&client_secret=twr9Wj7Qw16qrChi2lpl4dxTEWix9JuSg8mOgdF52F8&scope=non-expiring';
my $redirect_url = $scloud->get_authorization_url({scope => 'non-expiring'});
ok($url eq $redirect_url, 'Get Authrorization URL is success!');
# this access_token we got is non-expiring one. So we can use this for testing.
my $access_token = '6c56e362267b3c0613c1daf784de98c7';
$scloud->{access_token} = $access_token;

ok(my $me = $scloud->get('/me'),'get to me');
ok($me->is_success(),"and request worked");

ok(my $tracks = $scloud->get('/me/tracks'), 'get to /me/tracks');
ok($tracks->is_success(), "and the request succeeded");

ok($tracks = $scloud->get_list('/me/tracks'), "get_list on '/me/tracks'");
ok(@{$tracks}, "there are tracks - fragile as it could get deleted");
foreach my $track (@{$tracks})
{
    ok(my $id = $track->{id}, "and we got a track ID");
    my $file = $id . '.' . ( $track->{'original-format'} || 'wav');
    TODO:
    {
        local $TODO = 'Downloads not working yet';
         ok($scloud->download($id, $file), "download");
         ok(-s $file, "and the file got downloaded");
         unlink $file;
    }
}
