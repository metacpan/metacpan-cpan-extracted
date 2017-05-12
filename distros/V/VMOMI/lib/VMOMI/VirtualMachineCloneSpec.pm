package VMOMI::VirtualMachineCloneSpec;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['location', 'VirtualMachineRelocateSpec', 0, ],
    ['template', 'boolean', 0, ],
    ['config', 'VirtualMachineConfigSpec', 0, 1],
    ['customization', 'CustomizationSpec', 0, 1],
    ['powerOn', 'boolean', 0, ],
    ['snapshot', 'ManagedObjectReference', 0, 1],
    ['memory', 'boolean', 0, 1],
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
