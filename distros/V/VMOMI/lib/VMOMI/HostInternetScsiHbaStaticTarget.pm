package VMOMI::HostInternetScsiHbaStaticTarget;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['address', undef, 0, ],
    ['port', undef, 0, 1],
    ['iScsiName', undef, 0, ],
    ['discoveryMethod', undef, 0, 1],
    ['authenticationProperties', 'HostInternetScsiHbaAuthenticationProperties', 0, 1],
    ['digestProperties', 'HostInternetScsiHbaDigestProperties', 0, 1],
    ['supportedAdvancedOptions', 'OptionDef', 1, 1],
    ['advancedOptions', 'HostInternetScsiHbaParamValue', 1, 1],
    ['parent', undef, 0, 1],
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
