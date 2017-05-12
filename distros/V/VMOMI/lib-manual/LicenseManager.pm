package VMOMI::LicenseManager;
use parent 'VMOMI::ManagedObject';

use strict;
use warnings;

our @class_ancestors = (
    'ManagedObject',
);

our @class_members = (
    ['diagnostics', 'LicenseDiagnostics', 0, 0],
    ['evaluation', 'LicenseManagerEvaluationInfo', 0, 1],
    ['featureInfo', 'LicenseFeatureInfo', 1, 0],
    ['licenseAssignmentManager', 'ManagedObjectReference ', 0, 0],
    ['licensedEdition', undef, 0, 1],
    ['licenses', 'LicenseManagerLicenseInfo', 1, 1],
    ['source', 'LicenseSource', 0, 1],
    ['sourceAvailable', 'boolean', 0, 1],

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