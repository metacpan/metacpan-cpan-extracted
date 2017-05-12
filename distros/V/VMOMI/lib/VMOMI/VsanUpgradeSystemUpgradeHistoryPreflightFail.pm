package VMOMI::VsanUpgradeSystemUpgradeHistoryPreflightFail;
use parent 'VMOMI::VsanUpgradeSystemUpgradeHistoryItem';

use strict;
use warnings;

our @class_ancestors = ( 
    'VsanUpgradeSystemUpgradeHistoryItem',
    'DynamicData',
);

our @class_members = ( 
    ['preflightResult', 'VsanUpgradeSystemPreflightCheckResult', 0, ],
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
