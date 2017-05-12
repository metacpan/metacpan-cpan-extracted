package VMOMI::VirtualAppSummary;
use parent 'VMOMI::ResourcePoolSummary';

use strict;
use warnings;

our @class_ancestors = ( 
    'ResourcePoolSummary',
    'DynamicData',
);

our @class_members = ( 
    ['product', 'VAppProductInfo', 0, 1],
    ['vAppState', 'VirtualAppVAppState', 0, 1],
    ['suspended', 'boolean', 0, 1],
    ['installBootRequired', 'boolean', 0, 1],
    ['instanceUuid', undef, 0, 1],
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
