package VMOMI::VirtualMachineUsageOnDatastore;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['datastore', 'ManagedObjectReference', 0, ],
    ['committed', undef, 0, ],
    ['uncommitted', undef, 0, ],
    ['unshared', undef, 0, ],
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
