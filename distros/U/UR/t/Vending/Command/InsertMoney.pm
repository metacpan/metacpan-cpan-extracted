package Vending::Command::InsertMoney;
use strict;
use warnings;

class Vending::Command::InsertMoney {
    is => 'Vending::Command',
    doc => 'Base abstract class for the money inserting commands',
    #is_abstract => 1,
    has => [
        name => { is => 'String'},  #, is_abstract => 1 },
    ]
};

sub execute {
    my $self = shift;

    my $name = $self->name();

    my $machine = $self->machine();
    my $worked =  $machine->insert($name);
    return $worked;
}

1;

