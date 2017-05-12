package VMOMI::VirtualMachineDefaultPowerOpInfo;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['powerOffType', undef, 0, 1],
    ['suspendType', undef, 0, 1],
    ['resetType', undef, 0, 1],
    ['defaultPowerOffType', undef, 0, 1],
    ['defaultSuspendType', undef, 0, 1],
    ['defaultResetType', undef, 0, 1],
    ['standbyAction', undef, 0, 1],
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
