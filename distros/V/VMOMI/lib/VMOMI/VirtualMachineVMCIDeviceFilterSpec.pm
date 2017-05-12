package VMOMI::VirtualMachineVMCIDeviceFilterSpec;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['rank', undef, 0, ],
    ['action', undef, 0, ],
    ['protocol', undef, 0, ],
    ['direction', undef, 0, ],
    ['lowerDstPortBoundary', undef, 0, 1],
    ['upperDstPortBoundary', undef, 0, 1],
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
