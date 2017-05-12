package VMOMI::DatastoreSummary;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['datastore', 'ManagedObjectReference', 0, 1],
    ['name', undef, 0, ],
    ['url', undef, 0, ],
    ['capacity', undef, 0, ],
    ['freeSpace', undef, 0, ],
    ['uncommitted', undef, 0, 1],
    ['accessible', 'boolean', 0, ],
    ['multipleHostAccess', 'boolean', 0, 1],
    ['type', undef, 0, ],
    ['maintenanceMode', undef, 0, 1],
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
