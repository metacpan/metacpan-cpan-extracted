package VMOMI::ClusterConfigSpecEx;
use parent 'VMOMI::ComputeResourceConfigSpec';

use strict;
use warnings;

our @class_ancestors = ( 
    'ComputeResourceConfigSpec',
    'DynamicData',
);

our @class_members = ( 
    ['dasConfig', 'ClusterDasConfigInfo', 0, 1],
    ['dasVmConfigSpec', 'ClusterDasVmConfigSpec', 1, 1],
    ['drsConfig', 'ClusterDrsConfigInfo', 0, 1],
    ['drsVmConfigSpec', 'ClusterDrsVmConfigSpec', 1, 1],
    ['rulesSpec', 'ClusterRuleSpec', 1, 1],
    ['orchestration', 'ClusterOrchestrationInfo', 0, 1],
    ['vmOrchestrationSpec', 'ClusterVmOrchestrationSpec', 1, 1],
    ['dpmConfig', 'ClusterDpmConfigInfo', 0, 1],
    ['dpmHostConfigSpec', 'ClusterDpmHostConfigSpec', 1, 1],
    ['vsanConfig', 'VsanClusterConfigInfo', 0, 1],
    ['vsanHostConfigSpec', 'VsanHostConfigInfo', 1, 1],
    ['groupSpec', 'ClusterGroupSpec', 1, 1],
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
