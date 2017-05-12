use strict;
use Test::More;

use VMware::vCloud;
use VMware::vCloud::vApp;
use VMware::API::vCloud;

# Check for connection info to run additonal tests
our %ENV;

my $host = $ENV{VCLOUD_HOST};
my $user = $ENV{VCLOUD_USER};
my $pass = $ENV{VCLOUD_PASS};
my $org  = $ENV{VCLOUD_ORG} || 'System';

unless ( $host and $user and $pass and $org ) {
    diag(
        "\n",
        "No host connection info found. Skipping additional tests.\n",
        "\n",
        "Set environment variables VCLOUD_HOST, VCLOUD_USER, VCLOUD_PASS, VCLOUD_ORG\n",
        "to run full test suite.\n",
        "\n",
    );
    plan skip_all => "No vCloud connection Information";
}

my $vcd = new_ok 'VMware::vCloud' => [ $host, $user, $pass, $org ];

# really minimal functional test - r/o so should be safe against any install
my $org_map = $vcd->list_orgs();
isa_ok( $org_map, 'HASH', 'Returned list of organisations' );

done_testing;
