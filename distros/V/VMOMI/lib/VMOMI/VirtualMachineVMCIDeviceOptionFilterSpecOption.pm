package VMOMI::VirtualMachineVMCIDeviceOptionFilterSpecOption;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['action', 'ChoiceOption', 0, ],
    ['protocol', 'ChoiceOption', 0, ],
    ['direction', 'ChoiceOption', 0, ],
    ['lowerDstPortBoundary', 'LongOption', 0, ],
    ['upperDstPortBoundary', 'LongOption', 0, ],
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
