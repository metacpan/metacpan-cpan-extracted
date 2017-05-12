package VMOMI::VMwareDVSHealthCheckCapability;
use parent 'VMOMI::DVSHealthCheckCapability';

use strict;
use warnings;

our @class_ancestors = ( 
    'DVSHealthCheckCapability',
    'DynamicData',
);

our @class_members = ( 
    ['vlanMtuSupported', 'boolean', 0, ],
    ['teamingSupported', 'boolean', 0, ],
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
