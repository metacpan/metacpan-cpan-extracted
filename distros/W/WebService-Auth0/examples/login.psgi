use warnings;
use strict;
use WebService::Auth0;
use Plack::Request;
use JSON::PP;

my $auth0 = WebService::Auth0->new(
  domain => 'jjn1056.auth0.com',
  client_secret => $ENV{AUTH0_SECRET},
  client_id => $ENV{AUTH0_CLIENT_ID} );

my $auth = $auth0->auth;

my $app = sub {
  my $req = Plack::Request->new(shift);
  if($req->path_info eq '/auth0/callback') {
    my ($user_info) = $auth->get_token({
      code=>$req->param('code'),
      grant_type=>'authorization_code',
      redirect_uri=>'http://localhost:5000/auth0/callback'
    })->catch(sub {
      die "Don't expect and error here and now";
    })->then(sub {
      my $token = shift;
      my $future = $auth->userinfo({
        access_token => $token->{access_token},
      })->catch(sub {
        die "Don't expect and error here and now";
      });
    })->get;
    return [
      200,
      ['Content-Type' => 'application/json'],
      [encode_json ($user_info)]
    ];
  } else {
    my ($location) = $auth->authorize({
      redirect_uri=>'http://localhost:5000/auth0/callback',
      connection=>'google-oauth2',
      response_type=>'code'})->catch(sub {
      die "Don't expect and error here and now";
    })->get;
    if($location) {
      return [
        302,
        ['Location' => $location],
        ["Redirecting to $location"]
      ];
    } else {
      return [
        200,
        ['Content-Type' => 'text/plain'],
        ['Hello World']
      ];
    }
  }
};
