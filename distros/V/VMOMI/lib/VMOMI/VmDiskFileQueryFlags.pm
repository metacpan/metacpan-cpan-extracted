package VMOMI::VmDiskFileQueryFlags;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['diskType', 'boolean', 0, ],
    ['capacityKb', 'boolean', 0, ],
    ['hardwareVersion', 'boolean', 0, ],
    ['controllerType', 'boolean', 0, 1],
    ['diskExtents', 'boolean', 0, 1],
    ['thin', 'boolean', 0, 1],
    ['encryption', 'boolean', 0, 1],
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
