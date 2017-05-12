package VMOMI::ClusterFixedSizeSlotPolicy;
use parent 'VMOMI::ClusterSlotPolicy';

use strict;
use warnings;

our @class_ancestors = ( 
    'ClusterSlotPolicy',
    'DynamicData',
);

our @class_members = ( 
    ['cpu', undef, 0, ],
    ['memory', undef, 0, ],
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
