
BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for release candidate testing');
  }
}

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";

use Test::More;

use HTTP::Request;
use Sub::Override;
## use Test::MockObject;

use WWW::Curl::Easy;

BEGIN {
    use_ok('WWW::Curl::UserAgent');
}

my $ua = WWW::Curl::UserAgent->new(
                                   timeout => 10000,
                                   connect_timeout => 5000,
                                   followlocation => 1,
                                  );


{
  # Test a standard non redirecting request.
  my $req = HTTP::Request->new( 'GET' => 'http://www.example.com' );
  my $resp = $ua->request($req);
  ok( $resp->is_success() , "Response is a success");
  ok( $resp->request() , "Got request from response");
  is( $resp->base()  , 'http://www.example.com' );
}

{
  # Test a redirecting one (will get to www.example.com)
  my $req = HTTP::Request->new( 'GET' => 'http://bit.ly/1h0ceQI' );
  my $resp = $ua->request($req);
  ok( $resp->is_success() , "Response is a success");
  ok( $resp->request() , "Got request from response");
  is( $resp->base()  , 'http://www.example.com/' );
}

done_testing();
