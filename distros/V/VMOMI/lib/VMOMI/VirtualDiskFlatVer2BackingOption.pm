package VMOMI::VirtualDiskFlatVer2BackingOption;
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
    ['split', 'BoolOption', 0, ],
    ['writeThrough', 'BoolOption', 0, ],
    ['growable', 'boolean', 0, ],
    ['hotGrowable', 'boolean', 0, ],
    ['uuid', 'boolean', 0, ],
    ['thinProvisioned', 'BoolOption', 0, 1],
    ['eagerlyScrub', 'BoolOption', 0, 1],
    ['deltaDiskFormat', 'ChoiceOption', 0, 1],
    ['deltaDiskFormatsSupported', 'VirtualDiskDeltaDiskFormatsSupported', 1, 1],
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
