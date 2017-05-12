#!perl -w
use strict;
use warnings;
use Test::More ;
use Log::Log4perl qw/:easy/;
Log::Log4perl->easy_init($ERROR);


## Mockable UserAgent
BEGIN{
  $ENV{LWP_UA_MOCK} ||= 'playback';
  $ENV{LWP_UA_MOCK_FILE} = __FILE__.'.lwp-mock.out';
  eval{ require  LWP::UserAgent::Mockable; LWP::UserAgent::Mockable->import(); };
  plan skip_all => 'Cannot load LWP::UserAgent::Mockable. Skipping' if $@;
}

use WebService::ReutersConnect qw/:demo/;

ok( my $reuters = WebService::ReutersConnect->new( { username => 'john', password => 'doe' }), "Ok build a reuter");

ok( $reuters->date_created()->isa('DateTime') , "Good date created type");
ok( ! $reuters->authToken() , "Ok cannot get an auth token from these credentials");
## try connecting with real credentials.
ok( $reuters = WebService::ReutersConnect->new({ username => $ENV{REUTERS_USERNAME} // REUTERS_DEMOUSER,
                                                 password => $ENV{REUTERS_PASSWORD} // REUTERS_DEMOPASSWORD,
                                                 user_agent => $reuters->user_agent(),
                                               }), "Ok build API");
ok( $reuters->authToken() , "Ok we have an authToken");

LWP::UserAgent::Mockable->finished;
done_testing();
