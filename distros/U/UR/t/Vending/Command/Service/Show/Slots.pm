package Vending::Command::Service::Show::Slots;
use strict;
use warnings;
use Vending;

class Vending::Command::Service::Show::Slots {
    is => 'UR::Object::Command::List',
    has => [
        subject_class_name => { value => 'Vending::MachineLocation' },
        show => { value => 'name,label,price,count,content_value_dollars' },
    ],
    doc => "Display information about what is in the machine's slots",
};

1;




