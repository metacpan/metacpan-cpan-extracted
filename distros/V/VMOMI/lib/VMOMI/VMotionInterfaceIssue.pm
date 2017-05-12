package VMOMI::VMotionInterfaceIssue;
use parent 'VMOMI::MigrationFault';

use strict;
use warnings;

our @class_ancestors = ( 
    'MigrationFault',
    'VimFault',
    'MethodFault',
);

our @class_members = ( 
    ['atSourceHost', 'boolean', 0, ],
    ['failedHost', undef, 0, ],
    ['failedHostEntity', 'ManagedObjectReference', 0, 1],
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
