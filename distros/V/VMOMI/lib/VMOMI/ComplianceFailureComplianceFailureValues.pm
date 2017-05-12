package VMOMI::ComplianceFailureComplianceFailureValues;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['comparisonIdentifier', undef, 0, ],
    ['profileInstance', undef, 0, 1],
    ['hostValue', 'anyType', 0, 1],
    ['profileValue', 'anyType', 0, 1],
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
