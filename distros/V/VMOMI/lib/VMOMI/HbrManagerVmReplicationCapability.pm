package VMOMI::HbrManagerVmReplicationCapability;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['vm', 'ManagedObjectReference', 0, ],
    ['supportedQuiesceMode', undef, 0, ],
    ['compressionSupported', 'boolean', 0, ],
    ['maxSupportedSourceDiskCapacity', undef, 0, ],
    ['minRpo', undef, 0, 1],
    ['fault', 'LocalizedMethodFault', 0, 1],
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
