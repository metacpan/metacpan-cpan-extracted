package VMOMI::VirtualMachineScsiPassthroughInfo;
use parent 'VMOMI::VirtualMachineTargetInfo';

use strict;
use warnings;

our @class_ancestors = ( 
    'VirtualMachineTargetInfo',
    'DynamicData',
);

our @class_members = ( 
    ['scsiClass', undef, 0, ],
    ['vendor', undef, 0, ],
    ['physicalUnitNumber', undef, 0, ],
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
