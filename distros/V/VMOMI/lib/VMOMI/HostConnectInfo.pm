package VMOMI::HostConnectInfo;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['serverIp', undef, 0, 1],
    ['inDasCluster', 'boolean', 0, 1],
    ['host', 'HostListSummary', 0, ],
    ['vm', 'VirtualMachineSummary', 1, 1],
    ['vimAccountNameRequired', 'boolean', 0, 1],
    ['clusterSupported', 'boolean', 0, 1],
    ['network', 'HostConnectInfoNetworkInfo', 1, 1],
    ['datastore', 'HostDatastoreConnectInfo', 1, 1],
    ['license', 'HostLicenseConnectInfo', 0, 1],
    ['capability', 'HostCapability', 0, 1],
);

sub get_class_ancestors {
    return @class_ancestors;
}

sub get_class_members {
    my $class = shift;
    my @super_members = $class->SUPER::get_class_members();
    return (@super_members, @class_members);
}

1;
