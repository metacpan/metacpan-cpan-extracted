package VMOMI::DVSConfigSpec;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['configVersion', undef, 0, 1],
    ['name', undef, 0, 1],
    ['numStandalonePorts', undef, 0, 1],
    ['maxPorts', undef, 0, 1],
    ['uplinkPortPolicy', 'DVSUplinkPortPolicy', 0, 1],
    ['uplinkPortgroup', 'ManagedObjectReference', 1, 1],
    ['defaultPortConfig', 'DVPortSetting', 0, 1],
    ['host', 'DistributedVirtualSwitchHostMemberConfigSpec', 1, 1],
    ['extensionKey', undef, 0, 1],
    ['description', undef, 0, 1],
    ['policy', 'DVSPolicy', 0, 1],
    ['vendorSpecificConfig', 'DistributedVirtualSwitchKeyedOpaqueBlob', 1, 1],
    ['contact', 'DVSContactInfo', 0, 1],
    ['switchIpAddress', undef, 0, 1],
    ['defaultProxySwitchMaxNumPorts', undef, 0, 1],
    ['infrastructureTrafficResourceConfig', 'DvsHostInfrastructureTrafficResource', 1, 1],
    ['networkResourceControlVersion', undef, 0, 1],
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
