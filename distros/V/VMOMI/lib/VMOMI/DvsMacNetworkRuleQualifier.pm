package VMOMI::DvsMacNetworkRuleQualifier;
use parent 'VMOMI::DvsNetworkRuleQualifier';

use strict;
use warnings;

our @class_ancestors = ( 
    'DvsNetworkRuleQualifier',
    'DynamicData',
);

our @class_members = ( 
    ['sourceAddress', 'MacAddress', 0, 1],
    ['destinationAddress', 'MacAddress', 0, 1],
    ['protocol', 'IntExpression', 0, 1],
    ['vlanId', 'IntExpression', 0, 1],
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
