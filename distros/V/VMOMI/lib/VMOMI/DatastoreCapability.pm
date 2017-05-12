package VMOMI::DatastoreCapability;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['directoryHierarchySupported', 'boolean', 0, ],
    ['rawDiskMappingsSupported', 'boolean', 0, ],
    ['perFileThinProvisioningSupported', 'boolean', 0, ],
    ['storageIORMSupported', 'boolean', 0, 1],
    ['nativeSnapshotSupported', 'boolean', 0, 1],
    ['topLevelDirectoryCreateSupported', 'boolean', 0, 1],
    ['seSparseSupported', 'boolean', 0, 1],
    ['vmfsSparseSupported', 'boolean', 0, 1],
    ['vsanSparseSupported', 'boolean', 0, 1],
    ['upitSupported', 'boolean', 0, 1],
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
