use strict;
use Test::More;

use VMware::vCloudDirector;

# Check for connection info to run additonal tests
our %ENV;

my $host = $ENV{VCLOUD_USER_HOST};
my $user = $ENV{VCLOUD_USER_USER};
my $pass = $ENV{VCLOUD_USER_PASS};
my $org  = $ENV{VCLOUD_USER_ORG};

unless ( $host and $user and $pass and $org ) {
    diag(
        "\n",
        "No host connection info found. Skipping additional tests.\n",
        "\n",
        "Set environment variables:\n",
        "    VCLOUD_USER_HOST, VCLOUD_USER_USER,\n",
        "    VCLOUD_USER_PASS, VCLOUD_USER_ORG\n",
        "to run full test suite.\n",
        "\n",
    );
    plan skip_all => "No vCloud connection Information";
}

subtest 'Connection test with correct parameters' => sub {
    my $vcd = new_ok 'VMware::vCloudDirector' => [
        hostname   => $host,
        username   => $user,
        password   => $pass,
        orgname    => $org,
        ssl_verify => 0,
    ];
    ok( ( $vcd->api->api_version > 1.0 ), 'API version seen and more than 1.0' );
    my $session = $vcd->api->login;
    isa_ok( $session, 'VMware::vCloudDirector::Object', 'Got an object back from login' );
    is( $session->type, 'session', 'The object is a session' );
    my @org_list = $vcd->org_list;
    ok( ( scalar(@org_list) == 1 ), 'Org list has single item (expected for User)' );
    my $myorg = $org_list[0];
    isa_ok( $myorg, 'VMware::vCloudDirector::Object', 'Org object is the right type' );
    is( $myorg->type, 'org', 'Org object is an Org object' );
    is( $myorg->name, $org,  'Org object matches our Org' );
    done_testing();
};

done_testing;
