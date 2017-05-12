package VMOMI::LicenseNonComplianceEvent;
use parent 'VMOMI::LicenseEvent';

use strict;
use warnings;

our @class_ancestors = ( 
    'LicenseEvent',
    'Event',
    'DynamicData',
);

our @class_members = ( 
    ['url', undef, 0, ],
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
