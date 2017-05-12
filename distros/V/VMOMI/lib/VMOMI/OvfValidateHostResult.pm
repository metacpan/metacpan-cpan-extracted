package VMOMI::OvfValidateHostResult;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['downloadSize', undef, 0, 1],
    ['flatDeploymentSize', undef, 0, 1],
    ['sparseDeploymentSize', undef, 0, 1],
    ['error', 'LocalizedMethodFault', 1, 1],
    ['warning', 'LocalizedMethodFault', 1, 1],
    ['supportedDiskProvisioning', undef, 1, 1],
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
