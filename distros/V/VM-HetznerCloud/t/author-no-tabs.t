
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/VM/HetznerCloud.pm',
    'lib/VM/HetznerCloud/API/Actions.pm',
    'lib/VM/HetznerCloud/API/Certificates.pm',
    'lib/VM/HetznerCloud/API/Datacenters.pm',
    'lib/VM/HetznerCloud/API/Firewalls.pm',
    'lib/VM/HetznerCloud/API/FloatingIps.pm',
    'lib/VM/HetznerCloud/API/Images.pm',
    'lib/VM/HetznerCloud/API/Isos.pm',
    'lib/VM/HetznerCloud/API/LoadBalancerTypes.pm',
    'lib/VM/HetznerCloud/API/LoadBalancers.pm',
    'lib/VM/HetznerCloud/API/Locations.pm',
    'lib/VM/HetznerCloud/API/Networks.pm',
    'lib/VM/HetznerCloud/API/PlacementGroups.pm',
    'lib/VM/HetznerCloud/API/Pricing.pm',
    'lib/VM/HetznerCloud/API/PrimaryIps.pm',
    'lib/VM/HetznerCloud/API/ServerTypes.pm',
    'lib/VM/HetznerCloud/API/Servers.pm',
    'lib/VM/HetznerCloud/API/SshKeys.pm',
    'lib/VM/HetznerCloud/API/Volumes.pm',
    'lib/VM/HetznerCloud/APIBase.pm',
    'lib/VM/HetznerCloud/Schema.pm',
    't/base/attrs.t',
    't/base/base.t',
    't/data/servers_empty_list.txt',
    't/data/servers_get.txt',
    't/data/servers_list.txt',
    't/lib/TestClient.pm',
    't/server/base.t',
    't/server/cloud.t',
    't/server/get_server.t'
);

notabs_ok($_) foreach @files;
done_testing;
