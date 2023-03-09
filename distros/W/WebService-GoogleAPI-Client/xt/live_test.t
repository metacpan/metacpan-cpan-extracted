use Test2::V0;
use Test2::Tools::Spec;

# TODO - make a simple test which creates a file, lists it, then deletes it, for
# both a service account and a regular account.

use WebService::GoogleAPI::Client;

bail_out <<NEEDS_CREDS unless my $user_creds = $ENV{GAPI_XT_USER_CREDS};
This test requires real credentials with access to the
https://www.googleapis.com/auth/drive scope. Please set the GAPI_XT_USER_CREDS
environment variable to the gapi.json file and user email joined by a :

See CONTRIBUTING for more details
NEEDS_CREDS

bail_out <<NEEDS_USER unless my $service_creds = $ENV{GAPI_XT_SERVICE_CREDS};
This test requires real service account credentials with access to 
https://www.googleapis.com/auth/drive scope (which I think is there by default).
Please set the GAPI_XT_SERVICE_CREDS environment variable to your service account file.

See CONTRIBUTING for more details
NEEDS_USER


my ($path, $email) = split /:/, $user_creds;
my $u = WebService::GoogleAPI::Client->new(
  gapi_json => $path,
  user      => $email
);

my $s = WebService::GoogleAPI::Client->new(
  service_account => $service_creds,
  scopes          => ['https://www.googleapis.com/auth/drive']
);

my $filename = 'a-rather-unlikely-named-file-for-xt-testing';

describe 'file creation and deletion' => sub {
  my $ua;
  case 'user account'    => sub { $ua = $u };
  case 'service account' => sub { $ua = $s };

  tests 'doing it' => sub {
    my $res = $ua->api_query({
      api_endpoint_id => 'drive.files.create',
      options         => { name => $filename }
    });

    is $res->json('/name'), $filename, 'request worked';
    my $id = $res->json('/id');

    $res = $ua->api_query({
      api_endpoint_id => 'drive.files.delete',
      options         => { fileId => $id }
    });

    is $res->code, 204, 'delete went as planned';
  };
};


done_testing;
