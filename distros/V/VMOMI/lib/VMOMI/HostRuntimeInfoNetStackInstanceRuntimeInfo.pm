package VMOMI::HostRuntimeInfoNetStackInstanceRuntimeInfo;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['netStackInstanceKey', undef, 0, ],
    ['state', undef, 0, 1],
    ['vmknicKeys', undef, 1, 1],
    ['maxNumberOfConnections', undef, 0, 1],
    ['currentIpV6Enabled', 'boolean', 0, 1],
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
