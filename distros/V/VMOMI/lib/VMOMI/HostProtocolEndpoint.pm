package VMOMI::HostProtocolEndpoint;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['peType', undef, 0, ],
    ['type', undef, 0, 1],
    ['uuid', undef, 0, ],
    ['hostKey', 'ManagedObjectReference', 1, 1],
    ['storageArray', undef, 0, 1],
    ['nfsServer', undef, 0, 1],
    ['nfsDir', undef, 0, 1],
    ['nfsServerScope', undef, 0, 1],
    ['nfsServerMajor', undef, 0, 1],
    ['nfsServerAuthType', undef, 0, 1],
    ['nfsServerUser', undef, 0, 1],
    ['deviceId', undef, 0, 1],
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
