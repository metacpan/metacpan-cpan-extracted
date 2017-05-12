use strict;
use warnings;
use Test::More tests => 4;
use lib qw(lib);
use WWW::Mixpanel;

my $YOUR_TESTING_API_TOKEN = $ENV{MIXPANEL_TESTING_API_TOKEN};

if ( !$YOUR_TESTING_API_TOKEN ) {
  my $d = <<INFO;

  If you would like to run Mixpanel tests against your API token to observe the results,
  please set the environment variable MIXPANEL_TESTING_API_TOKEN
  and re-run the tests.

  I suggest creating a separate test project under your mixpanel account, which
  can be used for testing.

  Mixpanel does not provide a testing token, and only returns 1 / 0
  if the data is properly encoded.
INFO

  diag $d;
}

SKIP: {
  skip 'No personal API token provided, skipping Live tests', 4 unless $YOUR_TESTING_API_TOKEN;

  ok( my $mp = WWW::Mixpanel->new($YOUR_TESTING_API_TOKEN) );
  ok( $mp->people_set('testuser@test.com','Test' => 'true', '$first_name' => 'test', '$last_name' => 'user'), 'People API set' );
  ok( $mp->people_increment( 'testuser@test.com', 'tests' => 1  ), 'People api increment' );
  ok( $mp->people_track_charge( 'testuser@test.com', 26.00 ), 'People api track charge' );
}

done_testing;
