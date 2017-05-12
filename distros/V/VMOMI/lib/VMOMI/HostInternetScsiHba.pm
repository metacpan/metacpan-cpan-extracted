package VMOMI::HostInternetScsiHba;
use parent 'VMOMI::HostHostBusAdapter';

use strict;
use warnings;

our @class_ancestors = ( 
    'HostHostBusAdapter',
    'DynamicData',
);

our @class_members = ( 
    ['isSoftwareBased', 'boolean', 0, ],
    ['canBeDisabled', 'boolean', 0, 1],
    ['networkBindingSupport', 'HostInternetScsiHbaNetworkBindingSupportType', 0, 1],
    ['discoveryCapabilities', 'HostInternetScsiHbaDiscoveryCapabilities', 0, ],
    ['discoveryProperties', 'HostInternetScsiHbaDiscoveryProperties', 0, ],
    ['authenticationCapabilities', 'HostInternetScsiHbaAuthenticationCapabilities', 0, ],
    ['authenticationProperties', 'HostInternetScsiHbaAuthenticationProperties', 0, ],
    ['digestCapabilities', 'HostInternetScsiHbaDigestCapabilities', 0, 1],
    ['digestProperties', 'HostInternetScsiHbaDigestProperties', 0, 1],
    ['ipCapabilities', 'HostInternetScsiHbaIPCapabilities', 0, ],
    ['ipProperties', 'HostInternetScsiHbaIPProperties', 0, ],
    ['supportedAdvancedOptions', 'OptionDef', 1, 1],
    ['advancedOptions', 'HostInternetScsiHbaParamValue', 1, 1],
    ['iScsiName', undef, 0, ],
    ['iScsiAlias', undef, 0, 1],
    ['configuredSendTarget', 'HostInternetScsiHbaSendTarget', 1, 1],
    ['configuredStaticTarget', 'HostInternetScsiHbaStaticTarget', 1, 1],
    ['maxSpeedMb', undef, 0, 1],
    ['currentSpeedMb', undef, 0, 1],
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
