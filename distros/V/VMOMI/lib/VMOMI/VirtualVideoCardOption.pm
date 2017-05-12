package VMOMI::VirtualVideoCardOption;
use parent 'VMOMI::VirtualDeviceOption';

use strict;
use warnings;

our @class_ancestors = ( 
    'VirtualDeviceOption',
    'DynamicData',
);

our @class_members = ( 
    ['videoRamSizeInKB', 'LongOption', 0, 1],
    ['numDisplays', 'IntOption', 0, 1],
    ['useAutoDetect', 'BoolOption', 0, 1],
    ['support3D', 'BoolOption', 0, 1],
    ['use3dRendererSupported', 'BoolOption', 0, 1],
    ['graphicsMemorySizeInKB', 'LongOption', 0, 1],
    ['graphicsMemorySizeSupported', 'BoolOption', 0, 1],
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
