package VMOMI::ScsiLun;
use parent 'VMOMI::HostDevice';

use strict;
use warnings;

our @class_ancestors = ( 
    'HostDevice',
    'DynamicData',
);

our @class_members = ( 
    ['key', undef, 0, 1],
    ['uuid', undef, 0, ],
    ['descriptor', 'ScsiLunDescriptor', 1, 1],
    ['canonicalName', undef, 0, 1],
    ['displayName', undef, 0, 1],
    ['lunType', undef, 0, ],
    ['vendor', undef, 0, 1],
    ['model', undef, 0, 1],
    ['revision', undef, 0, 1],
    ['scsiLevel', undef, 0, 1],
    ['serialNumber', undef, 0, 1],
    ['durableName', 'ScsiLunDurableName', 0, 1],
    ['alternateName', 'ScsiLunDurableName', 1, 1],
    ['standardInquiry', undef, 1, 1],
    ['queueDepth', undef, 0, 1],
    ['operationalState', undef, 1, ],
    ['capabilities', 'ScsiLunCapabilities', 0, 1],
    ['vStorageSupport', undef, 0, 1],
    ['protocolEndpoint', 'boolean', 0, 1],
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
