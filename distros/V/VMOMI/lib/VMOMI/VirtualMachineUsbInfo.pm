package VMOMI::VirtualMachineUsbInfo;
use parent 'VMOMI::VirtualMachineTargetInfo';

use strict;
use warnings;

our @class_ancestors = ( 
    'VirtualMachineTargetInfo',
    'DynamicData',
);

our @class_members = ( 
    ['description', undef, 0, ],
    ['vendor', undef, 0, ],
    ['product', undef, 0, ],
    ['physicalPath', undef, 0, ],
    ['family', undef, 1, 1],
    ['speed', undef, 1, 1],
    ['summary', 'VirtualMachineSummary', 0, 1],
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
