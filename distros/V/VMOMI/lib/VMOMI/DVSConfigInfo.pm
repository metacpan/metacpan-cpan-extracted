package VMOMI::DVSConfigInfo;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['uuid', undef, 0, ],
    ['name', undef, 0, ],
    ['numStandalonePorts', undef, 0, ],
    ['numPorts', undef, 0, ],
    ['maxPorts', undef, 0, ],
    ['uplinkPortPolicy', 'DVSUplinkPortPolicy', 0, ],
    ['uplinkPortgroup', 'ManagedObjectReference', 1, 1],
    ['defaultPortConfig', 'DVPortSetting', 0, ],
    ['host', 'DistributedVirtualSwitchHostMember', 1, 1],
    ['productInfo', 'DistributedVirtualSwitchProductSpec', 0, ],
    ['targetInfo', 'DistributedVirtualSwitchProductSpec', 0, 1],
    ['extensionKey', undef, 0, 1],
    ['vendorSpecificConfig', 'DistributedVirtualSwitchKeyedOpaqueBlob', 1, 1],
    ['policy', 'DVSPolicy', 0, 1],
    ['description', undef, 0, 1],
    ['configVersion', undef, 0, ],
    ['contact', 'DVSContactInfo', 0, ],
    ['switchIpAddress', undef, 0, 1],
    ['createTime', undef, 0, ],
    ['networkResourceManagementEnabled', 'boolean', 0, 1],
    ['defaultProxySwitchMaxNumPorts', undef, 0, 1],
    ['healthCheckConfig', 'DVSHealthCheckConfig', 1, 1],
    ['infrastructureTrafficResourceConfig', 'DvsHostInfrastructureTrafficResource', 1, 1],
    ['networkResourceControlVersion', undef, 0, 1],
    ['vmVnicNetworkResourcePool', 'DVSVmVnicNetworkResourcePool', 1, 1],
    ['pnicCapacityRatioForReservation', undef, 0, 1],
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
