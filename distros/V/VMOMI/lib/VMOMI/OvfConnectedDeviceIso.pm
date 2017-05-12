package VMOMI::OvfConnectedDeviceIso;
use parent 'VMOMI::OvfConnectedDevice';

use strict;
use warnings;

our @class_ancestors = ( 
    'OvfConnectedDevice',
    'OvfHardwareExport',
    'OvfExport',
    'OvfFault',
    'VimFault',
    'MethodFault',
);

our @class_members = ( 
    ['filename', undef, 0, ],
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
