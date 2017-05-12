package VMOMI::VirtualMachineFileLayoutEx;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['file', 'VirtualMachineFileLayoutExFileInfo', 1, 1],
    ['disk', 'VirtualMachineFileLayoutExDiskLayout', 1, 1],
    ['snapshot', 'VirtualMachineFileLayoutExSnapshotLayout', 1, 1],
    ['timestamp', undef, 0, ],
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
