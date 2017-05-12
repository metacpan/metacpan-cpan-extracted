package VMOMI::HostHardwareStatusInfo;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['memoryStatusInfo', 'HostHardwareElementInfo', 1, 1],
    ['cpuStatusInfo', 'HostHardwareElementInfo', 1, 1],
    ['storageStatusInfo', 'HostStorageElementInfo', 1, 1],
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
