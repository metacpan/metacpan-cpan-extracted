package VMOMI::ToolsConfigInfo;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['toolsVersion', undef, 0, 1],
    ['toolsInstallType', undef, 0, 1],
    ['afterPowerOn', 'boolean', 0, 1],
    ['afterResume', 'boolean', 0, 1],
    ['beforeGuestStandby', 'boolean', 0, 1],
    ['beforeGuestShutdown', 'boolean', 0, 1],
    ['beforeGuestReboot', 'boolean', 0, 1],
    ['toolsUpgradePolicy', undef, 0, 1],
    ['pendingCustomization', undef, 0, 1],
    ['customizationKeyId', 'CryptoKeyId', 0, 1],
    ['syncTimeWithHost', 'boolean', 0, 1],
    ['lastInstallInfo', 'ToolsConfigInfoToolsLastInstallInfo', 0, 1],
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
