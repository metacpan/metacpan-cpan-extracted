package Ticketmaster;

use 5.008008;
use strict;
use warnings;


our $VERSION = '1.02';

sub new {
	my $class = shift;
	my $type = ref($class) || $class;
	my $self = bless {}, $type;

	$self->{'coins'} = [];
	$self->reload({ @_ }) if @_;
	$self;
}

sub reload { 
	my $self = shift;
	$self->{'store'} = { @_ };

	$self->{'min_coin'} = shift @{ [ sort {$a <=> $b} keys %{$self->{'store'}} ] };
}

sub change {
	my $self = shift;
	my $change = shift;

	return [] if $change <= 0;
	$self->{'change'} = $change;
	$self->_calculate;

	$self->{'coins'};
}

sub _calculate {
	my $self = shift;
	my $limit = shift;

	my $store = $self->{'store'};
	my $coin = $self->_max_coin($limit);

	if ($coin) {
		push (@{$self->{'coins'}}, $coin);
		return if $self->{'change'} == 0;
		$self->_calculate($coin);
	}else{
		# give up if no way to make change
		my $pop_coin = $self->_withdrawal;
		return unless $pop_coin;
		$self->_calculate($pop_coin - 1);
	}
}

sub _withdrawal {
	my $self = shift;
	my $store = $self->{'store'};
	my $coins = $self->{'coins'};

	my $coin = pop @$coins;
	$self->{'change'} += $coin;
	$store->{$coin} += 1;
	return if scalar @$coins == 0 && $coin == $self->{'min_coin'};
	return $coin;
}

sub balance {
	my $self = shift;
	
	my %balance;
	foreach (sort keys %{$self->{'store'}}) {
		if ($self->{'store'}->{$_} != 0) {
			$balance{$_} = $self->{'store'}->{$_};
		}
	}
	\%balance;
}

sub _max_coin {
	my $self = shift;
	my $limit = shift;
	my $store = $self->{'store'};

	foreach my $coin (sort {$b  <=>  $a} keys %$store) {
		# child coins shouldn't be  bigger than his parent
		next if $limit && $coin > $limit;
		next unless $coin <= $self->{'change'};
		next unless $store->{$coin} > 0;
		$store->{$coin} -= 1;
		$self->{'change'} -= $coin;
		my @available_coins = grep { $_ if $_ < $coin && $store->{$_} > 0 } keys %$store;
		$self->{'available_coins'} = \@available_coins;
		return $coin;
	}
	return;
}

sub add_coins {
	my $self = shift;
	my $coins = { @_ };
	my $store = $self->{'store'};

	my %new_store;
	foreach my $pair ($coins, $store) {
		while (my ($key, $value) = each %$pair) {
			if (exists $new_store{$key}) {
				$new_store{$key} += $value;
			}else{
				$new_store{$key} = $value;
			}
		}
	}
	$self->reload(%new_store);
}


1;

