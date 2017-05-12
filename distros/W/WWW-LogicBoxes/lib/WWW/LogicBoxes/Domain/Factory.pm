package WWW::LogicBoxes::Domain::Factory;

use strict;
use warnings;

use WWW::LogicBoxes::Domain;
use WWW::LogicBoxes::DomainTransfer;

use Carp;

our $VERSION = '1.9.0'; # VERSION
# ABSTRACT: Domain Factory for Building Domain Objects from Responses

sub construct_from_response {
    my $self = shift;
    my $response = shift;

    if( !$response ) {
        return;
    }

    if( $response->{actiontype} ) {
        if( $response->{actiontype} eq 'AddTransferDomain' ) {
            return WWW::LogicBoxes::DomainTransfer->construct_from_response( $response );
        }
        elsif( $response->{actiontype} eq 'DelDomain' || $response->{actiontype} eq 'ModContact' ) {
            return WWW::LogicBoxes::Domain->construct_from_response( $response );
        }
        else {
            croak $response->{actiontype} . ' is an unknown action type';
        }
    }
    else {
        return WWW::LogicBoxes::Domain->construct_from_response( $response );
    }
}

1;

__END__
