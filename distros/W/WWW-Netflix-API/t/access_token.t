#!perl

use strict;
use warnings;
use Test::More;
use WWW::Netflix::API;
$|=1;

my %env = map { $_ => $ENV{"WWW_NETFLIX_API__".uc($_)} } qw/
	consumer_key
	consumer_secret
	login_user
	login_pass
/;

if( ! $env{consumer_key} ){
  plan skip_all => 'Make sure that ENV vars are set for consumer_key, etc';
  exit;
}
plan tests => 14;

my $netflix = WWW::Netflix::API->new({
	consumer_key => $env{consumer_key},
	consumer_secret => $env{consumer_secret},
});

my $user = $env{login_user};
my $pass = $env{login_pass};

ok( $user, "have login name: $user" );
ok( $pass, "have login password" );

my ($access_token, $access_secret, $user_id) = $netflix->RequestAccess( $user, $pass );
is( $netflix->content_error, undef, 'no error' );

ok( $access_token,  "got access_token: " . $access_token );
ok( $access_secret, "got access_secret" );
ok( $user_id,       "got user_id: " . $user_id );

#######
# Test login failure
($access_token, $access_secret, $user_id) = $netflix->RequestAccess( $user . rand(), $pass );
is( $netflix->content_error, undef, 'no error' );

is( $access_token,  undef, "no access_token" );
is( $access_secret,  undef, "no access_secret" );
is( $user_id,  undef, "no user_id" );


#######
# Test login failure
$netflix->consumer_secret( '' );
($access_token, $access_secret, $user_id) = $netflix->RequestAccess( $user . rand(), $pass );
like( $netflix->content_error, qr/^POST Request to ".+?" failed \(401 Unauthorized\): "Invalid Signature"$/i, 'proper error' );

is( $access_token,  undef, "no access_token" );
is( $access_secret,  undef, "no access_secret" );
is( $user_id,  undef, "no user_id" );

