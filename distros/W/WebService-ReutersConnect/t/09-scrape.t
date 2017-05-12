#!perl -w
use strict;
use warnings;
use Test::More ;
use Log::Log4perl qw/:easy/;
Log::Log4perl->easy_init($INFO);

## Mockable UserAgent
BEGIN{
  $ENV{LWP_UA_MOCK} ||= 'playback';
  $ENV{LWP_UA_MOCK_FILE} = __FILE__.'.lwp-mock.out';
  eval{ require  LWP::UserAgent::Mockable; LWP::UserAgent::Mockable->import(); };
  plan skip_all => 'Cannot load LWP::UserAgent::Mockable. Skipping' if $@;
}

use WebService::ReutersConnect;

ok( my $reuters = WebService::ReutersConnect->new(), "Ok build a reuter");
ok( my @channels = $reuters->channels() ,"Ok can get channels from scraped demo accout");

LWP::UserAgent::Mockable->finished;
done_testing();
