package VMOMI::HostProfileConfigInfo;
use parent 'VMOMI::ProfileConfigInfo';

use strict;
use warnings;

our @class_ancestors = ( 
    'ProfileConfigInfo',
    'DynamicData',
);

our @class_members = ( 
    ['applyProfile', 'HostApplyProfile', 0, 1],
    ['defaultComplyProfile', 'ComplianceProfile', 0, 1],
    ['defaultComplyLocator', 'ComplianceLocator', 1, 1],
    ['customComplyProfile', 'ComplianceProfile', 0, 1],
    ['disabledExpressionList', undef, 1, 1],
    ['description', 'ProfileDescription', 0, 1],
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
