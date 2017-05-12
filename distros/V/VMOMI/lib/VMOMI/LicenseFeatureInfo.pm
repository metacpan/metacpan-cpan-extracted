package VMOMI::LicenseFeatureInfo;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['key', undef, 0, ],
    ['featureName', undef, 0, ],
    ['featureDescription', undef, 0, 1],
    ['state', 'LicenseFeatureInfoState', 0, 1],
    ['costUnit', undef, 0, ],
    ['sourceRestriction', undef, 0, 1],
    ['dependentKey', undef, 1, 1],
    ['edition', 'boolean', 0, 1],
    ['expiresOn', undef, 0, 1],
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
