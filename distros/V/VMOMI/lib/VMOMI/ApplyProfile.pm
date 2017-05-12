package VMOMI::ApplyProfile;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['enabled', 'boolean', 0, ],
    ['policy', 'ProfilePolicy', 1, 1],
    ['profileTypeName', undef, 0, 1],
    ['profileVersion', undef, 0, 1],
    ['property', 'ProfileApplyProfileProperty', 1, 1],
    ['favorite', 'boolean', 0, 1],
    ['toBeMerged', 'boolean', 0, 1],
    ['toReplaceWith', 'boolean', 0, 1],
    ['toBeDeleted', 'boolean', 0, 1],
    ['copyEnableStatus', 'boolean', 0, 1],
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
