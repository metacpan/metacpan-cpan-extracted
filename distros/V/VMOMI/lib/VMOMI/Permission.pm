package VMOMI::Permission;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['entity', 'ManagedObjectReference', 0, 1],
    ['principal', undef, 0, ],
    ['group', 'boolean', 0, ],
    ['roleId', undef, 0, ],
    ['propagate', 'boolean', 0, ],
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
