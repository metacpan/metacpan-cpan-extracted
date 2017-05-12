package Vending::Command::Service::Show::Money;
use strict;
use warnings;

class Vending::Command::Service::Show::Money {
    is_abstract => 1,
    is => 'Vending::Command::Service',
    doc => 'parent class for show change and show bank',
    has => [
        location_name => { is => 'String', is_abstract => 1 },
    ],
};

sub execute {
    my $self = shift;

    my $machine = $self->machine();

    my $loc = $machine->machine_locations(name => $self->location_name);
    unless ($loc) {
        $self->error_message("There is no slot named ".$self->location_name);
        return;
    }

    my @coins = $loc->items;

    my %coins_by_type;
    my $total_value = 0;

    foreach my $coin ( @coins ) {
        $coins_by_type{$coin->name}++;
        $total_value += $coin->value_cents;
    }

    while(my($type,$count) = each %coins_by_type) {
        printf("%-7s:%6d\n", $type,$count);
    }
    printf("Total:\t\$%.2f\n",$total_value/100);
    return 1;

}
1;

