package VMOMI::SoftwarePackageCapability;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['liveInstallAllowed', 'boolean', 0, 1],
    ['liveRemoveAllowed', 'boolean', 0, 1],
    ['statelessReady', 'boolean', 0, 1],
    ['overlay', 'boolean', 0, 1],
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
