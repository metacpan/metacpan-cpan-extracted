package VMOMI::CustomizationGuiUnattended;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['password', 'CustomizationPassword', 0, 1],
    ['timeZone', undef, 0, ],
    ['autoLogon', 'boolean', 0, ],
    ['autoLogonCount', undef, 0, ],
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
