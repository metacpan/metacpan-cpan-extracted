use 5.12.0;
use strict;
use warnings;

use Test::More;

use lib 't';
use setup;

use_ok 'WWW::SFDC::Constants';

sub test_using_client {
  my $constants = shift;

  is $constants->needsMetaFile('documents'),
    1,
    "Documents should need meta files";

  is $constants->hasFolders('documents'),
    1,
    "Documents should need folders";

  is $constants->getEnding('reports'),
    '.report',
    "Reports should have a .report ending";

  is $constants->getDiskName('CustomObject'),
    'objects',
    "The CustomObject should be saved in objects/";

  is $constants->getName('objects'),
    'CustomObject',
    "objects/ should have API name CustomObject";

  ok $constants->getSubcomponentsXMLNames() > 0,
    "There should be multiple subcomponents";
}

## Online tests
if (my $client = setup::client()){
  test_using_client($client->Constants)
} else {
  diag "Skipping online tests: $setup::skip", 7;
}

## Offline tests
test_using_client(
  WWW::SFDC::Constants->new(TYPES => $setup::TYPES)
);

done_testing();
