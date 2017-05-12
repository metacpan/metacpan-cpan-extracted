package VMOMI::EVCAdmissionFailed;
use parent 'VMOMI::NotSupportedHostInCluster';

use strict;
use warnings;

our @class_ancestors = ( 
    'NotSupportedHostInCluster',
    'NotSupportedHost',
    'HostConnectFault',
    'VimFault',
    'MethodFault',
);

our @class_members = ( 
    ['faults', 'LocalizedMethodFault', 1, 1],
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
