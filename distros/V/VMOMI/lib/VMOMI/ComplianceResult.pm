package VMOMI::ComplianceResult;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['profile', 'ManagedObjectReference', 0, 1],
    ['complianceStatus', undef, 0, ],
    ['entity', 'ManagedObjectReference', 0, 1],
    ['checkTime', undef, 0, 1],
    ['failure', 'ComplianceFailure', 1, 1],
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
