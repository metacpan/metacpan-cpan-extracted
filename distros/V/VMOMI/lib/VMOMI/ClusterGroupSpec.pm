package VMOMI::ClusterGroupSpec;
use parent 'VMOMI::ArrayUpdateSpec';

use strict;
use warnings;

our @class_ancestors = ( 
    'ArrayUpdateSpec',
    'DynamicData',
);

our @class_members = ( 
    ['info', 'ClusterGroupInfo', 0, 1],
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
