package VMOMI::HostProfileCompleteConfigSpec;
use parent 'VMOMI::HostProfileConfigSpec';

use strict;
use warnings;

our @class_ancestors = ( 
    'HostProfileConfigSpec',
    'ProfileCreateSpec',
    'DynamicData',
);

our @class_members = ( 
    ['applyProfile', 'HostApplyProfile', 0, 1],
    ['customComplyProfile', 'ComplianceProfile', 0, 1],
    ['disabledExpressionListChanged', 'boolean', 0, ],
    ['disabledExpressionList', undef, 1, 1],
    ['validatorHost', 'ManagedObjectReference', 0, 1],
    ['validating', 'boolean', 0, 1],
    ['hostConfig', 'HostProfileConfigInfo', 0, 1],
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
