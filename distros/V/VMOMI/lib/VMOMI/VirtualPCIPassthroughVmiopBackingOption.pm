package VMOMI::VirtualPCIPassthroughVmiopBackingOption;
use parent 'VMOMI::VirtualPCIPassthroughPluginBackingOption';

use strict;
use warnings;

our @class_ancestors = ( 
    'VirtualPCIPassthroughPluginBackingOption',
    'VirtualDeviceBackingOption',
    'DynamicData',
);

our @class_members = ( 
    ['vgpu', 'StringOption', 0, ],
    ['maxInstances', undef, 0, ],
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
