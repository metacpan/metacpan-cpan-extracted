package VMOMI::ComplianceFailure;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['failureType', undef, 0, ],
    ['message', 'LocalizableMessage', 0, ],
    ['expressionName', undef, 0, 1],
    ['failureValues', 'ComplianceFailureComplianceFailureValues', 1, 1],
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
