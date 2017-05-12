use strict;
use warnings;
use utf8;

package Ukigumo::Client::Executor::Auto;
use Ukigumo::Client::Executor::Perl;
use Ukigumo::Client::Executor::Prove;
use Ukigumo::Constants;

sub run {
    my $self = shift;
    my $status = Ukigumo::Client::Executor::Perl->new()->run(@_);
    return $status if $status ne STATUS_NA;
    return Ukigumo::Client::Executor::Prove->new()->run(@_);
}

1;
