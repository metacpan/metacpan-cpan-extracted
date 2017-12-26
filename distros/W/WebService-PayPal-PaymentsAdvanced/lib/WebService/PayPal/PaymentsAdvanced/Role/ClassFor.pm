package WebService::PayPal::PaymentsAdvanced::Role::ClassFor;

use Moo::Role;

use namespace::autoclean;

our $VERSION = '0.000024';

## no critic (ProhibitUnusedPrivateSubroutines)
sub _class_for {
    my $self = shift;
    return 'WebService::PayPal::PaymentsAdvanced::' . shift;
}

1;
