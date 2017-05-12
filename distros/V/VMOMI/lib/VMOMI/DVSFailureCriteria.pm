package VMOMI::DVSFailureCriteria;
use parent 'VMOMI::InheritablePolicy';

use strict;
use warnings;

our @class_ancestors = ( 
    'InheritablePolicy',
    'DynamicData',
);

our @class_members = ( 
    ['checkSpeed', 'StringPolicy', 0, 1],
    ['speed', 'IntPolicy', 0, 1],
    ['checkDuplex', 'BoolPolicy', 0, 1],
    ['fullDuplex', 'BoolPolicy', 0, 1],
    ['checkErrorPercent', 'BoolPolicy', 0, 1],
    ['percentage', 'IntPolicy', 0, 1],
    ['checkBeacon', 'BoolPolicy', 0, 1],
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
