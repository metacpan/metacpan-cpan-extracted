package WWW::eNom::Role::Command::Domain::Transfer;

use strict;
use warnings;

use Moose::Role;
use MooseX::Params::Validate;

use WWW::eNom::Types qw( DomainName DomainTransfer PositiveInt );
use WWW::eNom::DomainRequest::Transfer;
use WWW::eNom::DomainTransfer;

use Data::Util qw( is_array_ref );
use Math::Currency;
use Try::Tiny;
use Carp;

requires 'submit', 'get_domain_privacy_wholesale_price';

our $VERSION = 'v2.6.0'; # VERSION
# ABSTRACT: Domain Transfer API Calls

sub transfer_domain {
    my $self = shift;
    my ( %args ) = validated_hash(
        \@_,
        request => { isa => DomainTransfer, coerce => 1 },
    );

    return try {
        my $domain_privacy_price;
        if( $args{request}->is_private ) {
            $domain_privacy_price = $self->get_domain_privacy_wholesale_price();
        }

        my $response = $self->submit({
            method => 'TP_CreateOrder',
            params => {
                %{ $args{request}->construct_request() },
                $domain_privacy_price ? ( IDPPrice => $domain_privacy_price->as_float ) : ( ),
            },
        });

        if( $response->{ErrCount} > 0 ) {
            croak 'Unknown error';
        }

        $self->get_transfer_by_order_id( $response->{transferorder}{transferorderdetail}{transferorderdetailid} );
    }
    catch {
        croak $_;
    };
}

sub get_transfer_by_order_id {
    my $self = shift;
    my ( $order_id ) = pos_validated_list( \@_, { isa => PositiveInt } );

    return try {
        my $response = $self->submit({
            method => 'TP_GetOrderDetail',
            params => {
                TransferOrderDetailID => $order_id,
            }
        });

        if( $response->{ErrCount} > 0 ) {
            if(    ( grep { $_ eq 'Transfer Order Detail record does not exist.' } @{ $response->{errors} } )
                || ( grep { $_ eq 'Invalid Transfer Order Detail ID' } @{ $response->{errors} } ) ) {
                croak 'No transfer found in your account with specified id';
            }

            croak 'Unknown error';
        }

        return WWW::eNom::DomainTransfer->construct_from_response( transfer_detail => $response->{transferorderdetail} );
    }
    catch {
        croak $_;
    };
}

sub get_transfer_by_name {
    my $self = shift;
    my ( $domain_name ) = pos_validated_list( \@_, { isa => DomainName } );

    return try {
        my $response = $self->submit({
            method => 'TP_GetDetailsByDomain',
            params => {
                Domain => $domain_name,
            }
        });

        if( $response->{ErrCount} > 0 ) {
            if( grep { $_ eq 'There are no transfer order details' } @{ $response->{errors} } ) {
                croak 'No transfer found for specified domain name';
            }

            croak 'Unknown error';
        }

        my @raw_transfer_orders;
        if( is_array_ref( $response->{TransferOrder} ) ) {
            @raw_transfer_orders = @{ $response->{TransferOrder} };
        }
        else {
            @raw_transfer_orders = ( $response->{TransferOrder} );
        }

        my @transfers;
        for my $transfer_order ( @raw_transfer_orders ) {
            my $order_id = $self->get_transfer_order_id_from_parent_order_id( $transfer_order->{orderid} );
            push @transfers, $self->get_transfer_by_order_id( $order_id );
        }

        return \@transfers;
    }
    catch {
        croak $_;
    };
}

sub get_transfer_order_id_from_parent_order_id {
    my $self = shift;
    my ( $parent_order_id ) = pos_validated_list( \@_, { isa => PositiveInt } );

    return try {
        my $response = $self->submit({
            method => 'TP_GetOrder',
            params => {
                TransferOrderID => $parent_order_id,
            }
        });

        if( $response->{ErrCount} > 0 ) {
            if( grep { $_ eq 'Transfer Order does not exist.' } @{ $response->{errors} } ) {
                croak 'No transfer found for specified parent order id';
            }

            croak 'Unknown error';
        }

        return $response->{transferorder}{transferorderdetail}{transferorderdetailid};
    }
    catch {
        croak $_;
    };
}

1;

__END__

=pod

=head1 NAME

WWW::eNom::Role::Command::Domain::Transfer - Domain Transfer API Calls

=head1 SYNOPSIS

    use WWW::eNom;
    use WWW::eNom::DomainRequest::Transfer;
    use WWW::eNom::DomainTransfer;

    my $api = WWW::eNom->new( ... );

    # Start a Domain Transfer
    my $transfer_request = WWW::eNom::DomainRequest::Transfer->new( ... );
    my $transfer         = $api->transfer_domain( request => $transfer_request );

    # Get the Status of An In Progress Transfer
    my $in_progress_transfer = WWW::eNom::DomainTransfer->new( ... );
    my $updated_transfer     = $api->get_transfer_by_order_id( $in_progress_transfer->order_id );

    # Get history of transfer attempts for a domain
    my $transfers = $api->get_transfer_by_name( 'drzigman.com' );

    for my $transfer (@{ $transfers }) {
        print 'Transfer Order ID: ' . $transfer->order_id . "\n";
        print 'Transfer Status:   ' . $transfer->status   . "\n";
    }

    # Get a Transfer's order_id by the parent order id
    my $order_id = $api->get_transfer_order_id_from_parent_order_id( 42 );
    my $transfer = $api->get_transfer_by_order_id( $order_id );

=head1 REQUIRES

=over 4

=item submit

=item get_domain_privacy_wholesale_price

This is needed in order to purchase domain privacy for instances of L<WWW::eNom::DomainRequest::Transfer> that have is_private set to true.

=back

=head1 DESCRIPTION

Implements domain transfer operations with the L<eNom|https://www.enom.com> API.

=head1 METHODS

=head2 transfer_domain

    my $transfer_request = WWW::eNom::DomainRequest::Transfer->new( ... );
    my $transfer         = $api->transfer_domain( request => $transfer_request );

Abstraction of the L<TP_CreateOrder|https://www.enom.com/api/API%20Topics/API_TP_CreateOrder.htm> eNom API Call.  Given a L<WWW::eNom::DomainRequest::Transfer> or a HashRef that can be coerced into a L<WWW::eNom::DomainRequest::Transfer>, attempts to start the domain transfer process to move the domain to L<eNom|https://www.enom.com>.  Returned is a provisional L<WWW::eNom::DomainTransfer> object.

B<NOTE> Unfortunately, eNom does not process it's transfer requests live, meaning if there are errors with the request (bad EPP Key, domain is not actually registered, etc) you won't find that out for several minutes after submitting the transfer request.  That's why a "provisional" L<WWW::eNom::DomainTransfer> object is returned.  It is recommended that you periodically check the status of the transfer by using the L<get_transfer_by_order_id> method, paying attention to the L<status|WWW::eNom::DomainTransfer/status> and L<status_id|WWW::eNom::DomainTransfer/status_id> to ensure the transfer is proceeding smoothly.

B<FURTHER NOTE> If a domain transfer fails for some reason you will have to submit an entirely new L<transfer_domain> request.  There is no way to "restart" a failed transfer.

=head2 get_transfer_by_order_id

    my $in_progress_transfer = WWW::eNom::DomainTransfer->new( ... );
    my $updated_transfer     = $api->get_transfer_by_order_id( $in_progress_transfer->order_id );

Abstract of the L<TP_GetOrderDetail|https://www.enom.com/api/API%20topics/api_TP_GetOrderDetail.htm> eNom API Call.  Given the order_id of an in progress domain transfer, returns an instance of L<WWW::eNom::DomainTransfer> with the latest available information.

Please pay special attention to pass the right order_id (a WWW::eNom::DomainTransfer->order_id is always the right order_id).  See L<WWW::eNom::DomainTransfer/order_id> for a discussion on the different types of order_ids.

=head2 get_transfer_by_name

    my $transfers = $api->get_transfer_by_name( 'drzigman.com' );

    for my $transfer (@{ $transfers }) {
        print 'Transfer Order ID: ' . $transfer->order_id . "\n";
        print 'Transfer Status:   ' . $transfer->status   . "\n";
    }

Abstraction of the L<TP_GetDetailsByDomain|https://www.enom.com/api/API%20topics/api_TP_GetDetailsByDomain.htm> eNom API Call.  Usually you want to make use of L<get_transfer_by_order_id> however there are several reasons why you make use of get_transfer_by_name.

=over 4

=item You don't know the order_id

You really should be saving the order_id but if you don't know it you can search by domain name

=item You want the fully history of all transfer attempts

The ArrayRef of L<WWW::eNom::DomainTransfer> objects returned contains the full history and what happened with each transfer attempt.

=back

Given a FQDN, returns an ArrayRef of L<WWW::eNom::DomainTransfer> objects representing all of the attempted transfers of the specified FQDN.

=head2 get_transfer_order_id_from_parent_order_id

    my $order_id = $api->get_transfer_order_id_from_parent_order_id( 42 );
    my $transfer = $api->get_transfer_by_order_id( $order_id );

Abstraction of the L<TP_GetOrder|https://www.enom.com/api/API%20topics/api_TP_GetOrder.htm> eNom API Call.  If you only have the parent_order_id for a domain transfer and not the actual transfer's order_id, this method will accept that parent_order_id and provide you with the correct order_id (for usage in methods such as get_transfer_by_order_id).

For a discussion about the different types of order_ids please see L<WWW::eNom::DomainTransfer/order_id>

=cut
