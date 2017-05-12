package VMOMI::ApplyHostProfileConfigurationSpec;
use parent 'VMOMI::ProfileExecuteResult';

use strict;
use warnings;

our @class_ancestors = ( 
    'ProfileExecuteResult',
    'DynamicData',
);

our @class_members = ( 
    ['host', 'ManagedObjectReference', 0, ],
    ['taskListRequirement', undef, 1, 1],
    ['taskDescription', 'LocalizableMessage', 1, 1],
    ['rebootStateless', 'boolean', 0, 1],
    ['rebootHost', 'boolean', 0, 1],
    ['faultData', 'LocalizedMethodFault', 0, 1],
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
