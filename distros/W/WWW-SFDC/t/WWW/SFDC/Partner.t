use 5.12.0;
use strict;
use warnings;
use Test::More;

use lib 't';
use setup;

use_ok 'WWW::SFDC::Partner';

SKIP: {

  my $client = setup::client() or skip $setup::skip, 2;

  ok my $partner = $client->Partner;

  ok my @results = $partner->query("SELECT Id,Name FROM User WHERE Profile.Name = 'System Administrator'");

  diag explain @results;

}

done_testing;
