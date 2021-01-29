package TestTools;
use strict;
use warnings;

use Exporter::Shiny qw/ gapi_json DEBUG user has_credentials set_credentials/;
use Mojo::File qw/curfile path/;
use WebService::GoogleAPI::Client::AuthStorage::GapiJSON;

my $gapi;

#try and find a good gapi.json to use here. Check as follows:
# for sanity, we only use the fake gapi.json in the t/ directory unless the user
# explicitly gives a GOOGLE_TOKENSFILE
$gapi = path($ENV{GOOGLE_TOKENSFILE} || curfile->dirname->sibling('gapi.json'));

sub gapi_json {
  return "$gapi";
}
sub user { $ENV{GMAIL_FOR_TESTING} // 'peter@shotgundriver.com' }

sub has_credentials { $gapi->stat && user }

sub set_credentials {
  my ($obj) = @_;
  my $storage = WebService::GoogleAPI::Client::AuthStorage::GapiJSON->new(
    path => "$gapi",
    user => user
  );
  $obj->ua->auth_storage($storage);
}


sub DEBUG { $ENV{GAPI_DEBUG_LEVEL} // 0 }

9033
