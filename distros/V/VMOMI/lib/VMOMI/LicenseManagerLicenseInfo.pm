package VMOMI::LicenseManagerLicenseInfo;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['licenseKey', undef, 0, ],
    ['editionKey', undef, 0, ],
    ['name', undef, 0, ],
    ['total', undef, 0, ],
    ['used', undef, 0, 1],
    ['costUnit', undef, 0, ],
    ['properties', 'KeyAnyValue', 1, 1],
    ['labels', 'KeyValue', 1, 1],
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
