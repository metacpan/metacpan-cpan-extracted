package VMOMI::LicenseAssignmentManagerLicenseAssignment;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['entityId', undef, 0, ],
    ['scope', undef, 0, 1],
    ['entityDisplayName', undef, 0, 1],
    ['assignedLicense', 'LicenseManagerLicenseInfo', 0, ],
    ['properties', 'KeyAnyValue', 1, 1],
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
