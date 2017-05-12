package Vending::Command::Outputter;
use strict;
use warnings;

class Vending::Command::Outputter {
    is_abstract => 1,
    is => 'Vending::Command',
    doc => 'Abstract parent class for things that output items to the user',
};

sub execute {
    my $self = shift;

    my @user_items = $self->_get_items_to_output();

    foreach my $item ( @user_items ) {
        print "You get: ",$item->name,"\n";
    }
    return 1;
}

    
