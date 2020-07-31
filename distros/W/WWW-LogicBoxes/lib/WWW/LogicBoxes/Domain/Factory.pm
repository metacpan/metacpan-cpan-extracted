package WWW::LogicBoxes::Domain::Factory;

use strict;
use warnings;

use WWW::LogicBoxes::Domain;
use WWW::LogicBoxes::DomainTransfer;

use Carp;

our $VERSION = '1.10.1'; # VERSION
# ABSTRACT: Domain Factory for Building Domain Objects from Responses

sub construct_from_response {
    my $self = shift;
    my $response = shift;

    if( !$response ) {
        return;
    }

    if( $response->{actiontype} ) {

        # actiontype is an undocumented return value.  I spoke with a LogicBoxes
        # engineer who told me that it identifies an action that has been
        # requested but not yet completed - their API is asynchronous and a
        # successful call simply means an action has been queued for processing.
        #
        # Furthermore, the range of values for actiontype is not well defined -
        # new values are added routinely as needed. Accordingly, we need to be
        # lenient in looking at this value.
        #
        # In general, the only actiontype we need to concern ourselves with is
        # AddtransferDomain, which means the domain is in the process of being
        # transfered to LogicBoxes.  That gets a different class constructed for
        # it. All other values should be treated normally.
        #
        # Known values include:
        # AddtransferDomain - domain is being transferred in
        # DelDomain - a domain is being deleted
        # ModContact - a contact is being updated
        # ParkDomain - a domain has expired and is being parked at the
        #       registrar for the redemption period.
        # RenewDomain - a domain is being renewed

        if( $response->{actiontype} eq 'AddTransferDomain' ) {
            return WWW::LogicBoxes::DomainTransfer->construct_from_response( $response );
        }
        else {
            return WWW::LogicBoxes::Domain->construct_from_response( $response );
        }
    }
    else {
        return WWW::LogicBoxes::Domain->construct_from_response( $response );
    }
}

1;

__END__
