package VMOMI::VirtualPCIControllerOption;
use parent 'VMOMI::VirtualControllerOption';

use strict;
use warnings;

our @class_ancestors = ( 
    'VirtualControllerOption',
    'VirtualDeviceOption',
    'DynamicData',
);

our @class_members = ( 
    ['numSCSIControllers', 'IntOption', 0, ],
    ['numEthernetCards', 'IntOption', 0, ],
    ['numVideoCards', 'IntOption', 0, ],
    ['numSoundCards', 'IntOption', 0, ],
    ['numVmiRoms', 'IntOption', 0, ],
    ['numVmciDevices', 'IntOption', 0, 1],
    ['numPCIPassthroughDevices', 'IntOption', 0, 1],
    ['numSasSCSIControllers', 'IntOption', 0, 1],
    ['numVmxnet3EthernetCards', 'IntOption', 0, 1],
    ['numParaVirtualSCSIControllers', 'IntOption', 0, 1],
    ['numSATAControllers', 'IntOption', 0, 1],
    ['numNVMEControllers', 'IntOption', 0, 1],
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
