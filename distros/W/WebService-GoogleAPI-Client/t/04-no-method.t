use Test2::V0;
use Test2::Require::Internet;
use lib 't/lib';
use TestTools qw/gapi_json DEBUG user/;
use WebService::GoogleAPI::Client;

my $gapi = WebService::GoogleAPI::Client->new(
  debug     => DEBUG,
  gapi_json => gapi_json,
  user      => user
);

ok dies {
  $gapi->_process_params({
    api_endpoint_id => 'jobs.non.existant',
    options         => {
      fields => 'your(fez)'
    }
  })
}, 'blows up if an endpoint does not exist';

ok dies {
  $gapi->_process_params({
    api_endpoint_id => 'i.am.non.existant',
    options         => {
      fields => 'your(fez)'
    }
  })
}, 'blows up if an API does not exist';

done_testing;
