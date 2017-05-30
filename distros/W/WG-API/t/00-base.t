#!/usr/bin/env perl
use 5.014;
use strict;
use warnings;
use lib ('lib');
use Test::More;

BEGIN {
    use_ok( 'WG::API' ) || say "WG::API loaded";
    use_ok( 'WG::API::Error' ) || say "WG::API::Error loaded"; 
    use_ok( 'WG::API::Auth' )  || say "WG::API::Auth loaded";
}

my $error;
my %error_params = ( 
    field => 'search',
    message => 'SEARCH_NOT_SPECIFIED',
    code => 402,
    value => 'null',
);

can_ok( 'WG::API::Error', qw/field message code value/);

eval { $error = WG::API::Error->new() };
ok( ! $error && $@, 'create error object without params' );

eval { $error = WG::API::Error->new( %error_params ) };
ok( $error && ! $@, 'create error object with valid params' );
isa_ok( $error, 'WG::API::Error', 'ISA ok for Error object' );

ok( $error->field eq $error_params{ 'field' }, 'error->field checked' );
ok( $error->message eq $error_params{ 'message' }, 'error->message checked' );
ok( $error->code eq $error_params{ 'code' }, 'error->code checked' );
ok( $error->value eq $error_params{ 'value' }, 'error->value checked' );
ok( ! ref $error->raw, 'error->raw checked' );

my $wg;
eval {
    $wg = WG::API->new(application_id => $ENV{'WG_KEY'} || 'demo');
};
ok( $wg && ! $@, 'create general object');

isa_ok( $wg->net, 'WG::API::NET');
isa_ok( $wg->wot, 'WG::API::WoT');
isa_ok( $wg->wowp, 'WG::API::WoWp');
isa_ok( $wg->wows, 'WG::API::WoWs');
isa_ok( $wg->auth, 'WG::API::Auth');

isa_ok( $wg->net->ua, 'LWP::UserAgent');

my $auth = $wg->auth(debug=>1);
ok( $auth->login( nofollow => 1, redirect_uri => 'http://localhost/response' ), 'Get redirect uri' );
is( $auth->prolongate( access_token => 'xxx' ), undef, 'Prolongate with invalid access token' );
is( $auth->error->message, 'INVALID_ACCESS_TOKEN', 'Vaidate error message' );

ok( $auth->logout( access_token => 'xxx' ), 'Logout with invalid access token' );

done_testing();
