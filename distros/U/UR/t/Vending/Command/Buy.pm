package Vending::Command::Buy;
use strict;
use warnings;

use Vending;

class Vending::Command::Buy {
    is => 'Vending::Command::Outputter',
    doc => 'Attempt to get a sellable item',
    has => [
        bare_args => {
            is_optional => 1,
            is_many => 1,
            shell_args_position => 1
        }
    ]
};

sub help_detail {
    q(Buy an item from one of the vending machine's slots.  
Command line argument is one of the slot/button names);
}

sub _get_items_to_output {
    my $self = shift;

    my $slot_names = [$self->bare_args];
    my $machine = $self->machine;
    my @bought = $machine->buy(@$slot_names);
    return @bought;
}

1;

