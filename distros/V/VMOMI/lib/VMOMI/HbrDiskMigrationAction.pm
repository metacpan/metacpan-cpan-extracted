package VMOMI::HbrDiskMigrationAction;
use parent 'VMOMI::ClusterAction';

use strict;
use warnings;

our @class_ancestors = ( 
    'ClusterAction',
    'DynamicData',
);

our @class_members = ( 
    ['collectionId', undef, 0, ],
    ['collectionName', undef, 0, ],
    ['diskIds', undef, 1, ],
    ['source', 'ManagedObjectReference', 0, ],
    ['destination', 'ManagedObjectReference', 0, ],
    ['sizeTransferred', undef, 0, ],
    ['spaceUtilSrcBefore', undef, 0, 1],
    ['spaceUtilDstBefore', undef, 0, 1],
    ['spaceUtilSrcAfter', undef, 0, 1],
    ['spaceUtilDstAfter', undef, 0, 1],
    ['ioLatencySrcBefore', undef, 0, 1],
    ['ioLatencyDstBefore', undef, 0, 1],
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
