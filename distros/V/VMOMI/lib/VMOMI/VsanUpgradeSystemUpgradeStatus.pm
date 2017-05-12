package VMOMI::VsanUpgradeSystemUpgradeStatus;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['inProgress', 'boolean', 0, ],
    ['history', 'VsanUpgradeSystemUpgradeHistoryItem', 1, 1],
    ['aborted', 'boolean', 0, 1],
    ['completed', 'boolean', 0, 1],
    ['progress', undef, 0, 1],
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
