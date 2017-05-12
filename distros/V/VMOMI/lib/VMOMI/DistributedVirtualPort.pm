package VMOMI::DistributedVirtualPort;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['key', undef, 0, ],
    ['config', 'DVPortConfigInfo', 0, ],
    ['dvsUuid', undef, 0, ],
    ['portgroupKey', undef, 0, 1],
    ['proxyHost', 'ManagedObjectReference', 0, 1],
    ['connectee', 'DistributedVirtualSwitchPortConnectee', 0, 1],
    ['conflict', 'boolean', 0, ],
    ['conflictPortKey', undef, 0, 1],
    ['state', 'DVPortState', 0, 1],
    ['connectionCookie', undef, 0, 1],
    ['lastStatusChange', undef, 0, ],
    ['hostLocalPort', 'boolean', 0, 1],
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
