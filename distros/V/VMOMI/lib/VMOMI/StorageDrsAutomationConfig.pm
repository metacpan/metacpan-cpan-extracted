package VMOMI::StorageDrsAutomationConfig;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['spaceLoadBalanceAutomationMode', undef, 0, 1],
    ['ioLoadBalanceAutomationMode', undef, 0, 1],
    ['ruleEnforcementAutomationMode', undef, 0, 1],
    ['policyEnforcementAutomationMode', undef, 0, 1],
    ['vmEvacuationAutomationMode', undef, 0, 1],
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
