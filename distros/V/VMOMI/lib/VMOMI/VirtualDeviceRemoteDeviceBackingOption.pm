package VMOMI::VirtualDeviceRemoteDeviceBackingOption;
use parent 'VMOMI::VirtualDeviceBackingOption';

use strict;
use warnings;

our @class_ancestors = ( 
    'VirtualDeviceBackingOption',
    'DynamicData',
);

our @class_members = ( 
    ['autoDetectAvailable', 'BoolOption', 0, ],
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
