package VMOMI::DVSFeatureCapability;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['networkResourceManagementSupported', 'boolean', 0, ],
    ['vmDirectPathGen2Supported', 'boolean', 0, ],
    ['nicTeamingPolicy', undef, 1, 1],
    ['networkResourcePoolHighShareValue', undef, 0, 1],
    ['networkResourceManagementCapability', 'DVSNetworkResourceManagementCapability', 0, 1],
    ['healthCheckCapability', 'DVSHealthCheckCapability', 0, 1],
    ['rollbackCapability', 'DVSRollbackCapability', 0, 1],
    ['backupRestoreCapability', 'DVSBackupRestoreCapability', 0, 1],
    ['networkFilterSupported', 'boolean', 0, 1],
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
