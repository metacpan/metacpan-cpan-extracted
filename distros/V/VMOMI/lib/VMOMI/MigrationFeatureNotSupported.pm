package VMOMI::MigrationFeatureNotSupported;
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
    ['failedHostName', undef, 0, ],
    ['failedHost', 'ManagedObjectReference', 0, ],
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
