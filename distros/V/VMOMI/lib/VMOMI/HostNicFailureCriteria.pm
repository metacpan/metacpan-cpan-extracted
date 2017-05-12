package VMOMI::HostNicFailureCriteria;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['checkSpeed', undef, 0, 1],
    ['speed', undef, 0, 1],
    ['checkDuplex', 'boolean', 0, 1],
    ['fullDuplex', 'boolean', 0, 1],
    ['checkErrorPercent', 'boolean', 0, 1],
    ['percentage', undef, 0, 1],
    ['checkBeacon', 'boolean', 0, 1],
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
