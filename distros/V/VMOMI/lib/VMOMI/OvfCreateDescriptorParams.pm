package VMOMI::OvfCreateDescriptorParams;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['ovfFiles', 'OvfFile', 1, 1],
    ['name', undef, 0, 1],
    ['description', undef, 0, 1],
    ['includeImageFiles', 'boolean', 0, 1],
    ['exportOption', undef, 1, 1],
    ['snapshot', 'ManagedObjectReference', 0, 1],
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
