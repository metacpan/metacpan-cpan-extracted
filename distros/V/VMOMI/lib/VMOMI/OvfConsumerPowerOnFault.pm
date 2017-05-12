package VMOMI::OvfConsumerPowerOnFault;
use parent 'VMOMI::InvalidState';

use strict;
use warnings;

our @class_ancestors = ( 
    'InvalidState',
    'VimFault',
    'MethodFault',
);

our @class_members = ( 
    ['extensionKey', undef, 0, ],
    ['extensionName', undef, 0, ],
    ['description', undef, 0, ],
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
