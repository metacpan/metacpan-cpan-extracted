package VMOMI::VirtualMachineWindowsQuiesceSpec;
use parent 'VMOMI::VirtualMachineGuestQuiesceSpec';

use strict;
use warnings;

our @class_ancestors = ( 
    'VirtualMachineGuestQuiesceSpec',
    'DynamicData',
);

our @class_members = ( 
    ['vssBackupType', undef, 0, 1],
    ['vssBootableSystemState', 'boolean', 0, 1],
    ['vssPartialFileSupport', 'boolean', 0, 1],
    ['vssBackupContext', undef, 0, 1],
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
