package VMOMI::IORMNotSupportedHostOnDatastore;
use parent 'VMOMI::VimFault';

use strict;
use warnings;

our @class_ancestors = ( 
    'VimFault',
    'MethodFault',
);

our @class_members = ( 
    ['datastore', 'ManagedObjectReference', 0, ],
    ['datastoreName', undef, 0, ],
    ['host', 'ManagedObjectReference', 1, 1],
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
