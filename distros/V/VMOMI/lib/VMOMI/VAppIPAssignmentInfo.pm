package VMOMI::VAppIPAssignmentInfo;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['supportedAllocationScheme', undef, 1, 1],
    ['ipAllocationPolicy', undef, 0, 1],
    ['supportedIpProtocol', undef, 1, 1],
    ['ipProtocol', undef, 0, 1],
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
