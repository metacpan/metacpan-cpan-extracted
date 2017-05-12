#! /bin/false

package Suites::CustomerTest;

use strict;

use base qw (Test::Unit::TestCase);

use Suites::Customer;

use constant SLEEP_TIME => 1;

sub testRentingOneMovie
{
    my $self = shift;

    my $customer = Suites::Customer->new;

    $customer->rentMovie(1);
    
    $self->assert($customer->getTotalCharge == 4);
}

sub testRentingTwoMovies
{
    my $self = shift;

    my $customer = Suites::Customer->new;

    $customer->rentMovie(1);
    $customer->rentMovie(2);
    
    $self->assert_equals(4, $customer->getTotalCharge);

    sleep SLEEP_TIME;
}

sub testRentingThreeMovies
{
    my $self = shift;

    my $customer = Suites::Customer->new;

    $customer->rentMovie(1);
    $customer->rentMovie(2);
    $customer->rentMovie(3);
    
    $self->assert_num_equals(7.75, $customer->getTotalCharge);

    $self->assert_num_equals (1, 2);

    sleep SLEEP_TIME;
}

1;
