package VMOMI::HostProfileManagerCompositionValidationResultResultElement;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['target', 'ManagedObjectReference', 0, ],
    ['status', undef, 0, ],
    ['errors', 'LocalizableMessage', 1, 1],
    ['sourceDiffForToBeMerged', 'HostApplyProfile', 0, 1],
    ['targetDiffForToBeMerged', 'HostApplyProfile', 0, 1],
    ['toBeAdded', 'HostApplyProfile', 0, 1],
    ['toBeDeleted', 'HostApplyProfile', 0, 1],
    ['toBeDisabled', 'HostApplyProfile', 0, 1],
    ['toBeEnabled', 'HostApplyProfile', 0, 1],
    ['toBeReenableCC', 'HostApplyProfile', 0, 1],
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
