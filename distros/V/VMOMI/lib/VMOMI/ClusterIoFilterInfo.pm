package VMOMI::ClusterIoFilterInfo;
use parent 'VMOMI::IoFilterInfo';

use strict;
use warnings;

our @class_ancestors = ( 
    'IoFilterInfo',
    'DynamicData',
);

our @class_members = ( 
    ['opType', undef, 0, ],
    ['vibUrl', undef, 0, 1],
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
