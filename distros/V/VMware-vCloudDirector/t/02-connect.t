use strict;
use Test::More;
use Test::Exception;
use Test::LWP::UserAgent;
use FindBin;
use Path::Tiny;
use VMware::vCloudDirector;

FindBin->again;
my $datadir = path("$FindBin::Bin/data");

my %args = (
    hostname => 'vcloud.example.com',
    username => 'sysuser',
    password => 'syspass',
    orgname  => 'System',
);

# ------------------------------------------------------------------------
# fake useragent for testing
my $useragent = Test::LWP::UserAgent->new;

# These tests are currently all relentlessly positive, and need some negative
# and failure mode tests adding.
# There is also no checking of any POST content, nor of the authentication.
#
my $authcookie = 'b2a967d1b924449bbb903602c4c2446b';
my @responses  = (
    [ '000001.xml', qr|/api/versions|, 'text/xml', [] ],
    [   '000002.xml', qr|/api/sessions|,
        'application/vnd.vmware.vcloud.session+xml;version=5.6',
        [ 'x-vcloud-authorization' => $authcookie ]
    ],
    [ '000003.xml', qr|/api/org/$|, 'application/vnd.vmware.vcloud.orglist+xml;version=5.6', [] ],
    [   '000004.xml',
        qr|/api/org/342506a6-e7c8-11e6-9cfe-df67eba3672f|,
        'application/vnd.vmware.vcloud.org+xml;version=5.6', []
    ],
    [   '000005.xml',
        qr|/api/vdc/3425485b-e7c8-11e6-9cfe-a71fcbe754fd|,
        'application/vnd.vmware.vcloud.vdc+xml;version=5.6', []
    ],
    [   '000006.xml',
        qr|/api/vApp/vapp-3425823f-e7c8-11e6-9cfe-d0dcae80ccca|,
        'application/vnd.vmware.vcloud.vapp+xml;version=5.6', []
    ],
    [   '000007.xml',
        qr|/api/vApp/vapp-342582ac-e7c8-11e6-9cfe-ea7435803cc3|,
        'application/vnd.vmware.vcloud.vapp+xml;version=5.6', []
    ],
    [   '000008.xml',
        qr|/api/vApp/vapp-34258326-e7c8-11e6-9cfe-f83fead57d3f|,
        'application/vnd.vmware.vcloud.vapp+xml;version=5.6', []
    ],
    [   '000009.xml',
        qr|/api/vApp/vapp-342583b0-e7c8-11e6-9cfe-af000f5cd0e8|,
        'application/vnd.vmware.vcloud.vapp+xml;version=5.6', []
    ],
);
foreach (@responses) {
    $useragent->map_response(
        $_->[1],
        HTTP::Response->new(
            '200', HTTP::Status::status_message('200'),
            [ 'Content-Type' => $_->[2], @{ $_->[3] } ], $datadir->child( $_->[0] )->slurp
        ),
    );
}

# ------------------------------------------------------------------------
#
# Actual Tests!

my $vcd = new_ok 'VMware::vCloudDirector' => [ %args, _ua => $useragent ];
is( $vcd->api->api_version => '5.6', 'API version seen and is version 5.6' );

#
# Authentication and login
ok( not( $vcd->api->has_authorization_token ), 'Session token not set' );
my $session;
lives_ok( sub { $session = $vcd->api->login }, 'Login did not die' );
isa_ok( $session, 'VMware::vCloudDirector::Object', 'Got an object back from login' );
is( $session->type, 'session', 'The object is a session' );
isa_ok( $vcd->api->current_session, 'VMware::vCloudDirector::Object', 'Session object now set' );
ok( $vcd->api->has_authorization_token, 'Session token is now set' );
is( $vcd->api->authorization_token => $authcookie, 'Session token seen and matches' );
#
# Org list and grab Example Org
my @org_list = $vcd->org_list;
isa_ok( $org_list[0], 'VMware::vCloudDirector::Object', 'Org list object is the right type' );
is( $org_list[0]->type, 'org', 'Org list object is an Org object' );
ok( ( scalar(@org_list) > 1 ), 'Org list has multiple entries (needed for System)' );
my ($ex_org) = $vcd->org_grep( sub { $_->name eq 'Example' } );
ok( defined($ex_org), 'Example org has been found' );
isa_ok( $ex_org, 'VMware::vCloudDirector::Object', 'Example org object is the right type' );
is( $ex_org->type, 'org', 'Example org object is an Org object' );
#
# VDCs
my @vdc_objects = $ex_org->fetch_links( rel => 'down', type => 'vdc' );
is( scalar(@vdc_objects), 1, 'One VDC seen' );
my $vdc_obj = $vdc_objects[0];
isa_ok( $vdc_obj, 'VMware::vCloudDirector::Object', 'Example VDC object is the right type' );
is( $vdc_obj->type, 'vdc', 'Example VDC object is an VDC object' );
is( $vdc_obj->name, 'Example Working VDC', 'Example VDC object has correct name' );
#
# vApps & vAppTemplates
my @res_objects = $vdc_obj->build_sub_objects('ResourceEntity');
is( scalar(@res_objects), 7, '7 ResourceEntity seen in VDC' );
my @vapps = grep { $_->type eq 'vApp' } @res_objects;
is( scalar(@vapps), 4, '4 vApps seen in VDC' );
my ($vapp) = grep { $_->name eq 'vApp_system_2' } @vapps;
is( $vapp->name, 'vApp_system_2', 'Found vApp_system_2' );
#
# VMs
my @vms = grep { $_->type eq 'vm' } $vapp->build_children_objects();
is( scalar(@vms), 3, '3 VMs seen in VDC' );

done_testing;
