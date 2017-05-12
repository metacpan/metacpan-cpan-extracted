package VMOMI::VirtualDiskSeSparseBackingOption;
use parent 'VMOMI::VirtualDeviceFileBackingOption';

use strict;
use warnings;

our @class_ancestors = ( 
    'VirtualDeviceFileBackingOption',
    'VirtualDeviceBackingOption',
    'DynamicData',
);

our @class_members = ( 
    ['diskMode', 'ChoiceOption', 0, ],
    ['writeThrough', 'BoolOption', 0, ],
    ['growable', 'boolean', 0, ],
    ['hotGrowable', 'boolean', 0, ],
    ['uuid', 'boolean', 0, ],
    ['deltaDiskFormatsSupported', 'VirtualDiskDeltaDiskFormatsSupported', 1, ],
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
