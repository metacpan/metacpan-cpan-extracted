package VMOMI::HostStorageDeviceInfo;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['hostBusAdapter', 'HostHostBusAdapter', 1, 1],
    ['scsiLun', 'ScsiLun', 1, 1],
    ['scsiTopology', 'HostScsiTopology', 0, 1],
    ['multipathInfo', 'HostMultipathInfo', 0, 1],
    ['plugStoreTopology', 'HostPlugStoreTopology', 0, 1],
    ['softwareInternetScsiEnabled', 'boolean', 0, ],
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
