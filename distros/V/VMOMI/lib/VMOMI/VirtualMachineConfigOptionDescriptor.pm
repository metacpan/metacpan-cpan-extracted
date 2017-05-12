package VMOMI::VirtualMachineConfigOptionDescriptor;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['key', undef, 0, ],
    ['description', undef, 0, 1],
    ['host', 'ManagedObjectReference', 1, 1],
    ['createSupported', 'boolean', 0, 1],
    ['defaultConfigOption', 'boolean', 0, 1],
    ['runSupported', 'boolean', 0, 1],
    ['upgradeSupported', 'boolean', 0, 1],
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
