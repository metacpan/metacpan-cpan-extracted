package VMOMI::HostService;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['key', undef, 0, ],
    ['label', undef, 0, ],
    ['required', 'boolean', 0, ],
    ['uninstallable', 'boolean', 0, ],
    ['running', 'boolean', 0, ],
    ['ruleset', undef, 1, 1],
    ['policy', undef, 0, ],
    ['sourcePackage', 'HostServiceSourcePackage', 0, 1],
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
