package VMOMI::HostListSummary;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['host', 'ManagedObjectReference', 0, 1],
    ['hardware', 'HostHardwareSummary', 0, 1],
    ['runtime', 'HostRuntimeInfo', 0, 1],
    ['config', 'HostConfigSummary', 0, ],
    ['quickStats', 'HostListSummaryQuickStats', 0, ],
    ['overallStatus', 'ManagedEntityStatus', 0, ],
    ['rebootRequired', 'boolean', 0, ],
    ['customValue', 'CustomFieldValue', 1, 1],
    ['managementServerIp', undef, 0, 1],
    ['maxEVCModeKey', undef, 0, 1],
    ['currentEVCModeKey', undef, 0, 1],
    ['gateway', 'HostListSummaryGatewaySummary', 0, 1],
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
