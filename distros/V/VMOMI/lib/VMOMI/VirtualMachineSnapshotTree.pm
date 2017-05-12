package VMOMI::VirtualMachineSnapshotTree;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['snapshot', 'ManagedObjectReference', 0, ],
    ['vm', 'ManagedObjectReference', 0, ],
    ['name', undef, 0, ],
    ['description', undef, 0, ],
    ['id', undef, 0, 1],
    ['createTime', undef, 0, ],
    ['state', 'VirtualMachinePowerState', 0, ],
    ['quiesced', 'boolean', 0, ],
    ['backupManifest', undef, 0, 1],
    ['childSnapshotList', 'VirtualMachineSnapshotTree', 1, 1],
    ['replaySupported', 'boolean', 0, 1],
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
