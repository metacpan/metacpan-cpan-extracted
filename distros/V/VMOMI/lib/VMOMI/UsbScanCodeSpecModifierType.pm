package VMOMI::UsbScanCodeSpecModifierType;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['leftControl', 'boolean', 0, 1],
    ['leftShift', 'boolean', 0, 1],
    ['leftAlt', 'boolean', 0, 1],
    ['leftGui', 'boolean', 0, 1],
    ['rightControl', 'boolean', 0, 1],
    ['rightShift', 'boolean', 0, 1],
    ['rightAlt', 'boolean', 0, 1],
    ['rightGui', 'boolean', 0, 1],
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
