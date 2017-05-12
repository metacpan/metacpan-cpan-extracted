package VMOMI::VmConfigSpec;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['product', 'VAppProductSpec', 1, 1],
    ['property', 'VAppPropertySpec', 1, 1],
    ['ipAssignment', 'VAppIPAssignmentInfo', 0, 1],
    ['eula', undef, 1, 1],
    ['ovfSection', 'VAppOvfSectionSpec', 1, 1],
    ['ovfEnvironmentTransport', undef, 1, 1],
    ['installBootRequired', 'boolean', 0, 1],
    ['installBootStopDelay', undef, 0, 1],
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
