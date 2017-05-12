package VMOMI::HostNatServicePortForwardSpec;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['type', undef, 0, ],
    ['name', undef, 0, ],
    ['hostPort', undef, 0, ],
    ['guestPort', undef, 0, ],
    ['guestIpAddress', undef, 0, ],
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
