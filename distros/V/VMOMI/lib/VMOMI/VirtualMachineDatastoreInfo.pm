package VMOMI::VirtualMachineDatastoreInfo;
use parent 'VMOMI::VirtualMachineTargetInfo';

use strict;
use warnings;

our @class_ancestors = ( 
    'VirtualMachineTargetInfo',
    'DynamicData',
);

our @class_members = ( 
    ['datastore', 'DatastoreSummary', 0, ],
    ['capability', 'DatastoreCapability', 0, ],
    ['maxFileSize', undef, 0, ],
    ['maxVirtualDiskCapacity', undef, 0, 1],
    ['maxPhysicalRDMFileSize', undef, 0, 1],
    ['maxVirtualRDMFileSize', undef, 0, 1],
    ['mode', undef, 0, ],
    ['vStorageSupport', undef, 0, 1],
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
