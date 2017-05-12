package VMOMI::ProfileParameterMetadata;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['id', 'ExtendedElementDescription', 0, ],
    ['type', undef, 0, ],
    ['optional', 'boolean', 0, ],
    ['defaultValue', 'anyType', 0, 1],
    ['hidden', 'boolean', 0, 1],
    ['securitySensitive', 'boolean', 0, 1],
    ['readOnly', 'boolean', 0, 1],
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
