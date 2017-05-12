package VMOMI::VsanUpgradeSystemUpgradeHistoryItem;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['timestamp', undef, 0, ],
    ['host', 'ManagedObjectReference', 0, 1],
    ['message', undef, 0, ],
    ['task', 'ManagedObjectReference', 0, 1],
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
