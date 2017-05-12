package VMOMI::ResourcePoolResourceUsage;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['reservationUsed', undef, 0, ],
    ['reservationUsedForVm', undef, 0, ],
    ['unreservedForPool', undef, 0, ],
    ['unreservedForVm', undef, 0, ],
    ['overallUsage', undef, 0, ],
    ['maxUsage', undef, 0, ],
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
