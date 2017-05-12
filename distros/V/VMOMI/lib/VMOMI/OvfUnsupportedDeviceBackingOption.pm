package VMOMI::OvfUnsupportedDeviceBackingOption;
use parent 'VMOMI::OvfSystemFault';

use strict;
use warnings;

our @class_ancestors = ( 
    'OvfSystemFault',
    'OvfFault',
    'VimFault',
    'MethodFault',
);

our @class_members = ( 
    ['elementName', undef, 0, 1],
    ['instanceId', undef, 0, 1],
    ['deviceName', undef, 0, ],
    ['backingName', undef, 0, 1],
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
