use strict;
use warnings;

use FindBin qw/$Bin/;
use lib "$Bin/../lib";
use lib "$Bin/../inc";

use Webservice::OVH;
my $api = Webservice::OVH->new_from_json("../credentials.json");

my $service = $api->hosting->web->service('nak-west.de');

use DDP;
p $service;

p $service->service_infos;

my $response = $service->change_service_infos(
    renew => {
        automatic            => 'yes',
        forced               => 'no',
        delete_at_expiration => 'no',
        period               => 12
    }
);

use DDP;
p $response;

