package VMOMI::HostConfigSpec;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['nasDatastore', 'HostNasVolumeConfig', 1, 1],
    ['network', 'HostNetworkConfig', 0, 1],
    ['nicTypeSelection', 'HostVirtualNicManagerNicTypeSelection', 1, 1],
    ['service', 'HostServiceConfig', 1, 1],
    ['firewall', 'HostFirewallConfig', 0, 1],
    ['option', 'OptionValue', 1, 1],
    ['datastorePrincipal', undef, 0, 1],
    ['datastorePrincipalPasswd', undef, 0, 1],
    ['datetime', 'HostDateTimeConfig', 0, 1],
    ['storageDevice', 'HostStorageDeviceInfo', 0, 1],
    ['license', 'HostLicenseSpec', 0, 1],
    ['security', 'HostSecuritySpec', 0, 1],
    ['userAccount', 'HostAccountSpec', 1, 1],
    ['usergroupAccount', 'HostAccountSpec', 1, 1],
    ['memory', 'HostMemorySpec', 0, 1],
    ['activeDirectory', 'HostActiveDirectory', 1, 1],
    ['genericConfig', 'KeyAnyValue', 1, 1],
    ['graphicsConfig', 'HostGraphicsConfig', 0, 1],
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
