package Vending::Command::Menu;
use strict;
use warnings;

class Vending::Command::Menu {
    is => ['UR::Object::Command::List', 'Vending::Command' ],
    doc => 'Show the items available to buy',
    has => [
        subject_class_name => { is_constant => 1, value => 'Vending::MachineLocation' },
        filter => { value => 'is_buyable=1' },
        show => { value => 'name,label,price' },
    ],
};

sub execute {
    my $self = shift;

    my $super = $self->super_can('_execute_body');
    $super->($self,@_);

#$DB::single=1;
    my $machine = $self->machine;
    my $inserted = $machine->coin_box->content_value();
    if ($inserted) {
        printf("You have inserted \$%.2f so far\n", $inserted/100);
    } else {
        print "You have not inserted any money yet\n";
    }
    return 1;

}
1;

