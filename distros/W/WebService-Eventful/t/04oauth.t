use strict;
use warnings;
use WebService::Eventful;
use Test::More;

my $app_key      = $ENV{EVDB_APP_KEY};
my $key          = $ENV{EVDB_CONSUMER_KEY};
my $secret       = $ENV{EVDB_CONSUMER_SECRET};
my $oauth_token  = $ENV{EVDB_OAUTH_TOKEN};
my $oauth_secret = $ENV{EVDB_OAUTH_SECRET};
plan skip_all => 'set EVDB_APP_KEY EVDB_CONSUMER_KEY EVDB_CONSUMER_SECRET EVDB_OAUTH_TOKEN EVDB_OAUTH_SECRET enable this test'
  unless ($app_key && $key && $secret && $oauth_token && $oauth_secret);
plan tests => 2;

my $evdb = WebService::Eventful->new(app_key => $app_key, debug => 0, verbose => 0);

$evdb->setup_Oauth (
  consumer_key    =>  $key,
  consumer_secret =>  $secret,
  oauth_token     =>  $oauth_token,
  oauth_secret    =>  $oauth_secret);
  
my $app_info = $evdb->call('users/appkeys/list');
is(ref($app_info), 'HASH', 'app key data was returned');
is($app_info->{appkey}->{key}, $app_key , 'APP Key matches');
