package VMOMI::ClusterDasAdvancedRuntimeInfo;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['dasHostInfo', 'ClusterDasHostInfo', 0, 1],
    ['vmcpSupported', 'ClusterDasAdvancedRuntimeInfoVmcpCapabilityInfo', 0, 1],
    ['heartbeatDatastoreInfo', 'DasHeartbeatDatastoreInfo', 1, 1],
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
