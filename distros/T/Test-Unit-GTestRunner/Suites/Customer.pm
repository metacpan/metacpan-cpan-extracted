#! /bin/false

package Suites::Customer;

use strict;

sub new
{
    bless {
	__total_charge => 0,
    }, shift;
}

sub rentMovie
{
    my ($self, $days_rented) = @_;

    $self->{__total_charge} += 2;
    
    if ($days_rented > 2) {
	$self->{__total_charge} += 1.75;
    }
}

sub getTotalCharge
{
    shift->{__total_charge};
}

1;

