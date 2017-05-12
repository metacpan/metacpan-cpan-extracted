package VMOMI::ClusterComputeResource;
use parent 'VMOMI::ComputeResource';

use strict;
use warnings;

our @class_ancestors = (
    'ComputeResource',
    'ManagedEntity',
    'ExtensibleManagedObject',
    'ManagedObject',
);

our @class_members = ( 
    ['actionHistory', 'ClusterActionHistory', 1, 0],
    ['configuration', 'ClusterConfigInfo', 0, 1],
    ['drsFault', 'ClusterDrsFaults', 1, 0],
    ['drsRecommendation', 'ClusterDrsRecommendation', 1, 0],
    ['migrationHistory', 'ClusterDrsMigration', 1, 0],
    ['recommendation', 'ClusterRecommendation', 1, 0],
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
