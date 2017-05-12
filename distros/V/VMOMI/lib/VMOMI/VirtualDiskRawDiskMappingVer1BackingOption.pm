package VMOMI::VirtualDiskRawDiskMappingVer1BackingOption;
use parent 'VMOMI::VirtualDeviceDeviceBackingOption';

use strict;
use warnings;

our @class_ancestors = ( 
    'VirtualDeviceDeviceBackingOption',
    'VirtualDeviceBackingOption',
    'DynamicData',
);

our @class_members = ( 
    ['descriptorFileNameExtensions', 'ChoiceOption', 0, 1],
    ['compatibilityMode', 'ChoiceOption', 0, ],
    ['diskMode', 'ChoiceOption', 0, ],
    ['uuid', 'boolean', 0, ],
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
