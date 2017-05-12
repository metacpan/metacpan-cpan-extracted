package VMOMI::ReplicationVmFault;
use parent 'VMOMI::ReplicationFault';

use strict;
use warnings;

our @class_ancestors = ( 
    'ReplicationFault',
    'VimFault',
    'MethodFault',
);

our @class_members = ( 
    ['reason', undef, 0, 1],
    ['state', undef, 0, 1],
    ['instanceId', undef, 0, 1],
    ['vm', 'ManagedObjectReference', 0, 1],
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
