package VMOMI::VmCloneFailedEvent;
use parent 'VMOMI::VmCloneEvent';

use strict;
use warnings;

our @class_ancestors = ( 
    'VmCloneEvent',
    'VmEvent',
    'Event',
    'DynamicData',
);

our @class_members = ( 
    ['destFolder', 'FolderEventArgument', 0, ],
    ['destName', undef, 0, ],
    ['destHost', 'HostEventArgument', 0, ],
    ['reason', 'LocalizedMethodFault', 0, ],
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
