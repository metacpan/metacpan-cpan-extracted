package VMOMI::DvsTrafficRule;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['key', undef, 0, 1],
    ['description', undef, 0, 1],
    ['sequence', undef, 0, 1],
    ['qualifier', 'DvsNetworkRuleQualifier', 1, 1],
    ['action', 'DvsNetworkRuleAction', 0, 1],
    ['direction', undef, 0, 1],
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
