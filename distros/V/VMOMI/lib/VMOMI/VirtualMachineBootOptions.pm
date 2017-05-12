package VMOMI::VirtualMachineBootOptions;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['bootDelay', undef, 0, 1],
    ['enterBIOSSetup', 'boolean', 0, 1],
    ['efiSecureBootEnabled', 'boolean', 0, 1],
    ['bootRetryEnabled', 'boolean', 0, 1],
    ['bootRetryDelay', undef, 0, 1],
    ['bootOrder', 'VirtualMachineBootOptionsBootableDevice', 1, 1],
    ['networkBootProtocol', undef, 0, 1],
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
