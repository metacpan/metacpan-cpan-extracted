package VMOMI::HostLowLevelProvisioningManagerVmMigrationStatus;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['migrationId', undef, 0, ],
    ['type', undef, 0, ],
    ['source', 'boolean', 0, ],
    ['consideredSuccessful', 'boolean', 0, ],
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
