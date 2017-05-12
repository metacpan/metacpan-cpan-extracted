package VMOMI::VirtualUSBControllerOption;
use parent 'VMOMI::VirtualControllerOption';

use strict;
use warnings;

our @class_ancestors = ( 
    'VirtualControllerOption',
    'VirtualDeviceOption',
    'DynamicData',
);

our @class_members = ( 
    ['autoConnectDevices', 'BoolOption', 0, ],
    ['ehciSupported', 'BoolOption', 0, ],
    ['supportedSpeeds', undef, 1, 1],
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
