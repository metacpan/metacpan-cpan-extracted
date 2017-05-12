package VMOMI::Capability;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['provisioningSupported', 'boolean', 0, ],
    ['multiHostSupported', 'boolean', 0, ],
    ['userShellAccessSupported', 'boolean', 0, ],
    ['supportedEVCMode', 'EVCMode', 1, 1],
    ['networkBackupAndRestoreSupported', 'boolean', 0, 1],
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
