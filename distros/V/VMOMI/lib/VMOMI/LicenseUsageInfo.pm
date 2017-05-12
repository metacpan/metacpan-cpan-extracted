package VMOMI::LicenseUsageInfo;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['source', 'LicenseSource', 0, ],
    ['sourceAvailable', 'boolean', 0, ],
    ['reservationInfo', 'LicenseReservationInfo', 1, 1],
    ['featureInfo', 'LicenseFeatureInfo', 1, 1],
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
