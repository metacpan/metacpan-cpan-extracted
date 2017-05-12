package VMOMI::VAppProductInfo;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['key', undef, 0, ],
    ['classId', undef, 0, 1],
    ['instanceId', undef, 0, 1],
    ['name', undef, 0, 1],
    ['vendor', undef, 0, 1],
    ['version', undef, 0, 1],
    ['fullVersion', undef, 0, 1],
    ['vendorUrl', undef, 0, 1],
    ['productUrl', undef, 0, 1],
    ['appUrl', undef, 0, 1],
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
