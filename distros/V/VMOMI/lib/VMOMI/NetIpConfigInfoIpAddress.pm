package VMOMI::NetIpConfigInfoIpAddress;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['ipAddress', undef, 0, ],
    ['prefixLength', undef, 0, ],
    ['origin', undef, 0, 1],
    ['state', undef, 0, 1],
    ['lifetime', undef, 0, 1],
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
