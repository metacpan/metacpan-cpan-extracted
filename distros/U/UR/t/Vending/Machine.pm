package Vending::Machine;

use strict;
use warnings;

use Vending;

class Vending::Machine {
    table_name => 'MACHINE',
    id_by => [
        machine_id => { is => 'Integer' },
    ],
    has => [
        coin_box => { via => 'machine_locations', to => '-filter', where => [ name => 'box' ] },
        bank     => { via => 'machine_locations', to => '-filter', where => [ name => 'bank' ] },
        change_dispenser   => { via => 'machine_locations', to => '-filter', where => [ name => 'change' ] },
        address       => { is => 'Text', is_optional => 1 },
    ],
    has_many => [
        products        => { is => 'Vending::Product', reverse_as => 'machine' },
        items           => { is => 'Vending::Content', reverse_as => 'machine' },
        inventory_items => { is => 'Vending::Merchandise', reverse_as => 'machine' },
        item_types      => { is => 'Vending::ContentType', reverse_as => 'machine' },
        machine_locations           => { is => 'Vending::MachineLocation', reverse_as => 'machine' },
    ],
    data_source => 'Vending::DataSource::Machine',
};

sub insert {
    my($self, $item_name) = @_;

    my $coin_type = Vending::CoinType->get(name => $item_name);
    unless ($coin_type) {
        $self->error_message("This machine does not accept '$item_name' coins");
        return;
    }

    my $loc = $self->coin_box();
    my $coin = $loc->add_coin(type_id => $coin_type->type_id, machine_id => $self);

    return defined($coin);
}

sub coin_return {
    my $self = shift;

    my $loc = $self->coin_box;
    my @coins = $loc->items();
    my @returned_items = Vending::ReturnedItem->create_from_vend_items(@coins);

    return @returned_items;
}

sub empty_bank  {
    my $self = shift;

    my $loc = $self->bank();
    my @coins = $loc->items();
    my @returned_items = Vending::ReturnedItem->create_from_vend_items(@coins);

    return @returned_items;
}

sub empty_machine_location_by_name {
    my($self,$name) = @_;

    my $loc = $self->machine_locations(name => $name);
    return unless $loc;
    unless ($loc->is_buyable) {
        die "You can only empty out inventory type machine_locations";
    }

    my @items = $loc->items();
    my @returned_items = Vending::ReturnedItem->create_from_vend_items(@items);

    return @returned_items;
}

sub buy {
    my($self,@machine_location_names) = @_;
    
    my $coin_box = $self->coin_box();
    my $transaction = UR::Context::Transaction->begin();

    my @returned_items = eval {

        my $users_money = $coin_box->content_value();

        my @bought_items;
        my %iterator_for_machine_location;

        foreach my $loc_name ( @machine_location_names ) {
            my $machine_location = $self->machine_locations(name => $loc_name);
            unless ($machine_location && $machine_location->is_buyable) {
                die "$loc_name is not a valid choice\n";
            }

            my $iter = $iterator_for_machine_location{$loc_name} || $machine_location->item_iterator();
            unless ($iter) {
                die "Problem creating iterator for $loc_name\n";
                return;
            }

            my $item = $iter->next();    # This is the one they'll buy
            unless ($item) {
                $self->error_message("Item $loc_name is empty");
                next;
            }
            
            push @bought_items, $item->dispense;
        }
        
        my @change;
        if (@bought_items) {
            @change = $self->_complete_purchase_and_make_change_for_selections(@bought_items);
        }

        return (@change,@bought_items);
    };

    if ($@) {
        my($error) = ($@ =~ m/^(.*?)\n/);
        $self->error_message("Couldn't process your purchase:\n$error");
        $transaction->rollback();
        return;
    } else {
        $transaction->commit();
        return @returned_items;
    }
}


# Note that this will die if there's a problem making change 
sub _complete_purchase_and_make_change_for_selections {
    my($self,@bought_items) = @_;

    my $coin_box = $self->coin_box();

    my $purchased_value = 0;
    foreach my $item ( @bought_items ) {
        $purchased_value += $item->cost_cents;
    }
    my $change_value = $coin_box->content_value() - $purchased_value;

    if ($change_value < 0) {
        die "You did not enter enough money\n";
    }

    # Put all the user's coins into the bank
    my $bank = $self->bank;
    $coin_box->transfer_items_to_machine_location($bank);

    if ($change_value == 0) {
        return;
    }

    # List of coin types in decreasing value
    my @available_coin_types = map { $_->name }
                               sort { $b->value_cents <=> $a->value_cents }
                               Vending::CoinType->get();

    my $change_dispenser = $self->change_dispenser;
    my @change;
    # Make change for the user
    MAKING_CHANGE:
    foreach my $coin_name ( @available_coin_types ) {
        my $coin_iter = $change_dispenser->coin_iterator(name => $coin_name);
        unless ($coin_iter) {
            die "Can't create iterator for Vending::Coin::Change\n";
        }
           
        THIS_coin_type:
        while ( my $coin = $coin_iter->next() ) {
            last if $change_value < $coin->value_cents;

            my($change_coin) = $coin->dispense;
            $change_value -= $change_coin->value;
            push @change, $change_coin;
        }
    }

    if ($change_value) {
        #$DB::single=1;
        die "Not enough change\n";
    }

    return @change;
}

sub _initialize_for_tests {
    my $self = shift;

    $_->delete foreach $self->inventory_items();
    $_->delete foreach $self->products();
    $_->delete foreach $self->items();
} 
    

1;
  
