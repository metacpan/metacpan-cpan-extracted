package VMOMI::VirtualSwitchProfile;
use parent 'VMOMI::ApplyProfile';

use strict;
use warnings;

our @class_ancestors = ( 
    'ApplyProfile',
    'DynamicData',
);

our @class_members = ( 
    ['key', undef, 0, ],
    ['name', undef, 0, ],
    ['link', 'LinkProfile', 0, ],
    ['numPorts', 'NumPortsProfile', 0, ],
    ['networkPolicy', 'NetworkPolicyProfile', 0, ],
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
