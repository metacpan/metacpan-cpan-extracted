package VMOMI::ClusterRuleInfo;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['key', undef, 0, 1],
    ['status', 'ManagedEntityStatus', 0, 1],
    ['enabled', 'boolean', 0, 1],
    ['name', undef, 0, 1],
    ['mandatory', 'boolean', 0, 1],
    ['userCreated', 'boolean', 0, 1],
    ['inCompliance', 'boolean', 0, 1],
    ['ruleUuid', undef, 0, 1],
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
