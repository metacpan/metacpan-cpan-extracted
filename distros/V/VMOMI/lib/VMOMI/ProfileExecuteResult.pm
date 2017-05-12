package VMOMI::ProfileExecuteResult;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['status', undef, 0, ],
    ['configSpec', 'HostConfigSpec', 0, 1],
    ['inapplicablePath', undef, 1, 1],
    ['requireInput', 'ProfileDeferredPolicyOptionParameter', 1, 1],
    ['error', 'ProfileExecuteError', 1, 1],
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
