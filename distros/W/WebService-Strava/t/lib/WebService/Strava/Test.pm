package WebService::Strava::Test;

use strict;
use warnings;
use WebService::Strava::Auth;
use Moo;
use Method::Signatures;
use IO::Socket;
use JSON 'from_json';
use Test::Most;

method test_with_auth($test, $number_tests) {
  SKIP: {
    skip "No auth credentials found.", $number_tests unless ( -e "$ENV{HOME}/.stravatest" );

    my $auth = WebService::Strava::Auth->new(
      config_file => "$ENV{HOME}/.stravatest",
    );

    $test->($auth, "Testing Live Strava API");
  }
}

method test_with_dancer($test, $number_tests) {
  SKIP: {
    eval {  
      require Dancer2; 
    };

    skip 'These tests are for cached testing and require Dancer2.', $number_tests if ($@);

    my $pid = fork();

    if (!$pid) {
      exec("t/bin/cached_api.pl");
    }

    my $config->{auth} = {
      client_id => '1234',
      client_secret => 'abcdefghijklmnopqrstuv123456',
      token_string => '{
        "create_time" : "1424243324",
        "access_token" : "abcdefghijklmnopqrstuv123456",
        "token_type" : "Bearer",
        "_class" : "LWP::Authen::OAuth2::AccessToken::Bearer"
      }',
    };

    my $auth = WebService::Strava::Auth->new(
      api_base => 'http://localhost:3001',
      config => $config,
    );

    # Lets check to see if we have a dancer2 instance up
    my $count = 0;
    while ($count < 10) {
      my $sock = IO::Socket::INET->new('localhost:3001');
      if ($sock && $sock->connected) {
        last;
      }
      sleep 1;
      $count++;
    }

    # And check if we're getting a JSON response
    my $data;
    eval {
      $data = from_json($auth->get("http://localhost:3001/athlete")->content);
    } or do {
      my $e = $@;
      print("Failed parsing json: $e\n");
    };

    TODO: {
      todo_skip "It seems offline testing doesn't work for you", $number_tests if (! $data || $count > 9);
      $test->($auth, "Testing Cached API");
    }

    # Kill Dancer
    kill 9, $pid;
  }
}

1;
