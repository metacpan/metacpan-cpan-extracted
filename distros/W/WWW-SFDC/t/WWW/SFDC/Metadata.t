use 5.12.0;
use strict;
use warnings;
use Test::More;
use Test::Exception;

use lib 't';
use setup;

require_ok 'WWW::SFDC::Metadata';

SKIP: { #only execute if creds provided

  my $client = setup::client() or skip $setup::skip, 4;

  ok my $metadata = $client->Metadata();

  ok my $manifest = $metadata->listMetadata(
    {type => "CustomObject"},
    {type => "ApexClass"},
    {type => "Profile"},
    {type => "CustomObject"},
    {type => "Report", folder => "FooReports"}
   ), "List Metadata"
     or skip "Can't retrieve or deploy because list failed", 2;

  ok my $base64ZipString = $metadata->retrieveMetadata($manifest),
    "Retrieve Metadata" or skip "Can't deploy because retrieve failed", 1;

  lives_ok {$metadata->deployMetadata($base64ZipString)}
    "Retrieve Metadata";

  TODO: {
    local $TODO = "test retrieve, deploy and list failures";

    ok 0;
  }
}

done_testing();
