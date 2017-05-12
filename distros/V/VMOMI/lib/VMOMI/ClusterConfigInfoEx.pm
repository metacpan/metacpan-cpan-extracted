package VMOMI::ClusterConfigInfoEx;
use parent 'VMOMI::ComputeResourceConfigInfo';

use strict;
use warnings;

our @class_ancestors = ( 
    'ComputeResourceConfigInfo',
    'DynamicData',
);

our @class_members = ( 
    ['dasConfig', 'ClusterDasConfigInfo', 0, ],
    ['dasVmConfig', 'ClusterDasVmConfigInfo', 1, 1],
    ['drsConfig', 'ClusterDrsConfigInfo', 0, ],
    ['drsVmConfig', 'ClusterDrsVmConfigInfo', 1, 1],
    ['rule', 'ClusterRuleInfo', 1, 1],
    ['orchestration', 'ClusterOrchestrationInfo', 0, 1],
    ['vmOrchestration', 'ClusterVmOrchestrationInfo', 1, 1],
    ['dpmConfigInfo', 'ClusterDpmConfigInfo', 0, 1],
    ['dpmHostConfig', 'ClusterDpmHostConfigInfo', 1, 1],
    ['vsanConfigInfo', 'VsanClusterConfigInfo', 0, 1],
    ['vsanHostConfig', 'VsanHostConfigInfo', 1, 1],
    ['group', 'ClusterGroupInfo', 1, 1],
    ['infraUpdateHaConfig', 'ClusterInfraUpdateHaConfigInfo', 0, 1],
    ['proactiveDrsConfig', 'ClusterProactiveDrsConfigInfo', 0, 1],
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
