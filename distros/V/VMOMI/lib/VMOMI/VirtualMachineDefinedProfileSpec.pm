package VMOMI::VirtualMachineDefinedProfileSpec;
use parent 'VMOMI::VirtualMachineProfileSpec';

use strict;
use warnings;

our @class_ancestors = ( 
    'VirtualMachineProfileSpec',
    'DynamicData',
);

our @class_members = ( 
    ['profileId', undef, 0, ],
    ['replicationSpec', 'ReplicationSpec', 0, 1],
    ['profileData', 'VirtualMachineProfileRawData', 0, 1],
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
