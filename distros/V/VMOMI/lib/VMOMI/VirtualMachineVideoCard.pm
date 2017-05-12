package VMOMI::VirtualMachineVideoCard;
use parent 'VMOMI::VirtualDevice';

use strict;
use warnings;

our @class_ancestors = ( 
    'VirtualDevice',
    'DynamicData',
);

our @class_members = ( 
    ['videoRamSizeInKB', undef, 0, 1],
    ['numDisplays', undef, 0, 1],
    ['useAutoDetect', 'boolean', 0, 1],
    ['enable3DSupport', 'boolean', 0, 1],
    ['use3dRenderer', undef, 0, 1],
    ['graphicsMemorySizeInKB', undef, 0, 1],
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
