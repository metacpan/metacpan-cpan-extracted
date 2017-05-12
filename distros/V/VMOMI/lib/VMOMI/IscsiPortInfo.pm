package VMOMI::IscsiPortInfo;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['vnicDevice', undef, 0, 1],
    ['vnic', 'HostVirtualNic', 0, 1],
    ['pnicDevice', undef, 0, 1],
    ['pnic', 'PhysicalNic', 0, 1],
    ['switchName', undef, 0, 1],
    ['switchUuid', undef, 0, 1],
    ['portgroupName', undef, 0, 1],
    ['portgroupKey', undef, 0, 1],
    ['portKey', undef, 0, 1],
    ['opaqueNetworkId', undef, 0, 1],
    ['opaqueNetworkType', undef, 0, 1],
    ['opaqueNetworkName', undef, 0, 1],
    ['externalId', undef, 0, 1],
    ['complianceStatus', 'IscsiStatus', 0, 1],
    ['pathStatus', undef, 0, 1],
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
