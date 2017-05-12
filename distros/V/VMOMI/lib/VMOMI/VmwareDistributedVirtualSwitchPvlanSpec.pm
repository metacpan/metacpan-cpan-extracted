package VMOMI::VmwareDistributedVirtualSwitchPvlanSpec;
use parent 'VMOMI::VmwareDistributedVirtualSwitchVlanSpec';

use strict;
use warnings;

our @class_ancestors = ( 
    'VmwareDistributedVirtualSwitchVlanSpec',
    'InheritablePolicy',
    'DynamicData',
);

our @class_members = ( 
    ['pvlanId', undef, 0, ],
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
