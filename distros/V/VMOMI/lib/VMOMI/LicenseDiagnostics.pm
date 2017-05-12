package VMOMI::LicenseDiagnostics;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['sourceLastChanged', undef, 0, ],
    ['sourceLost', undef, 0, ],
    ['sourceLatency', undef, 0, ],
    ['licenseRequests', undef, 0, ],
    ['licenseRequestFailures', undef, 0, ],
    ['licenseFeatureUnknowns', undef, 0, ],
    ['opState', 'LicenseManagerState', 0, ],
    ['lastStatusUpdate', undef, 0, ],
    ['opFailureMessage', undef, 0, ],
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
