package WWW::LogicBoxes::Role::Command::Domain::Transfer;

use strict;
use warnings;

use Moose::Role;
use MooseX::Params::Validate;

use WWW::LogicBoxes::Types qw( DomainName DomainTransfer Int );

use WWW::LogicBoxes::DomainRequest::Transfer;

use Try::Tiny;
use Carp;

requires 'submit', 'get_domain_by_id';

our $VERSION = '1.10.0'; # VERSION
# ABSTRACT: Domain Transfer API Calls

sub is_domain_transferable {
    my $self = shift;
    my ( $domain_name ) = pos_validated_list( \@_, { isa => DomainName } );

    return try {
        my $response = $self->submit({
            method => 'domains__validate_transfer',
            params => {
                'domain-name' => $domain_name
            }
        });

        return ( $response->{result} eq 'true' );
    }
    catch {
        if( $_ =~ m/is currently available for Registration/ ) {
            return;
        }

        croak $_;
    };
}

sub transfer_domain {
    my $self = shift;
    my ( %args ) = validated_hash(
        \@_,
        request => { isa => DomainTransfer, coerce => 1 },
    );

    my $response = $self->submit({
        method => 'domains__transfer',
        params => $args{request}->construct_request,
    });

    if( $response->{status} eq 'Failed' ) {
        if( $response->{actionstatusdesc} =~ m/Order Locked In Processing/ ) {
            croak 'Domain is locked';
        }
        else {
            croak $response->{actionstatusdesc};
        }
    }

    return $self->get_domain_by_id( $response->{entityid} );
}

sub delete_domain_transfer_by_id {
    my $self = shift;
    my ( $domain_id ) = pos_validated_list( \@_, { isa => Int } );

    return try {
        my $response = $self->submit({
            method => 'domains__cancel_transfer',
            params => {
                'order-id' => $domain_id,
            }
        });

        if( lc $response->{result} eq 'success' ) {
            return;
        }

        croak $response;
    }
    catch {
        if( $_ =~ m/You are not allowed to perform this action/ ) {
            croak 'No matching order found';
        }
        elsif( $_ =~ m|Invalid action status/action type for this operation| ) {
            croak 'Unable to delete';
        }

        croak $_;
    };
}

sub resend_transfer_approval_mail_by_id {
    my $self = shift;
    my ( $domain_id ) = pos_validated_list( \@_, { isa => Int } );

    return try {
        my $response = $self->submit({
            method => 'domains__resend_rfa',
            params => {
                'order-id' => $domain_id,
            }
        });

        if( lc $response->{result} eq 'true' ) {
            return;
        }

        croak $response;
    }
    catch {
        ## no critic ( RegularExpressions::ProhibitComplexRegexes )
        if( $_ =~ m/You are not allowed to perform this action/ ) {
            croak 'No matching pending transfer order found';
        }
        elsif( $_ =~ m/The current status of Transfer action for the domain name does not allow this operation/ ) {
            croak 'Domain is not pending admin approval';
        }
        ## use critic

        croak $_;
    };
}

1;

__END__
=pod

=head1 NAME

WWW::LogicBoxes::Role::Command::Domain::Transfer - Domain Transfer Related Operations

=head1 SYNOPSIS

    use WWW::LogicBoxes;
    use WWW::LogicBoxes::DomainTransfer;
    use WWW::LogicBoxes::DomainRequest::Transfer;

    my $logic_boxes = WWW::LogicBoxes->new( ... );

    # Check Transferability
    if( $logic_boxes->is_domain_transferable( 'some-domain.com' ) ) {
        print "Domain is transferable';
    }
    else {
        print "Domain is not transferable";
    }

    # Transfer Domain
    my $transfer_request = WWW::LogicBoxes::DomainRequest::Transfer->new( ... );
    my $domain_transfer  = $logic_boxes->transfer_domain( $transfer_request );

    # Deletion
    $logic_boxes->delete_domain_transfer_by_id( $domain_transfer->id );

    # Resend Transfer Approval Mail
    $logic_boxes->resend_transfer_approval_mail_by_id( $domain_transfer->id );

=head1 REQUIRES

=over 4

=item submit

=item get_domain_by_id

=back

=head1 DESCRIPTION

Implemented domain transfer related operations with the L<LogicBoxes'|http://www.logicobxes.com> API.

=head1 METHODS

=head2 is_domain_transferable

    use WWW::LogicBoxes;

    my $logic_boxes = WWW::LogicBoxes->new( ... );

    if( $logic_boxes->is_domain_transferable( 'some-domain.com' ) ) {
        print "Domain is transferable';
    }
    else {
        print "Domain is not transferable";
    }

Given a domain name, uses L<LogicBoxes|http://www.logicboxes.com> to determine if this domain is transferable in it's current state.

B<NOTE> L<LogicBoxes|http://www.logicboxes.com> will accept transfer requests even if the domain is not actually eligble for transfer so you should call this method before making a domain transfer request.

=head2 transfer_domain

    use WWW::LogicBoxes;
    use WWW::LogicBoxes::DomainTransfer;
    use WWW::LogicBoxes::DomainRequest::Transfer;

    my $logic_boxes = WWW::LogicBoxes->new( ... );

    my $transfer_request = WWW::LogicBoxes::DomainRequest::Transfer->new( ... );
    my $domain_transfer  = $logic_boxes->transfer_domain( $transfer_request );

Given a L<WWW::LogicBoxes::DomainRequest::Transfer> or a HashRef that can be coerced into a L<WWW::LogicBoxes::DomainRequest::Transfer>, attempt to transfer the domain with L<LogicBoxes|http://www.logicboxes.com>.

Returns a fully formed L<WWW::LogicBoxes::DomainTransfer>.

=head2 delete_domain_transfer_by_id

    use WWW::LogicBoxes;
    use WWW::LogicBoxes::DomainTransfer;
    use WWW::LogicBoxes::DomainRequest::Transfer;

    my $logic_boxes = WWW::LogicBoxes->new( ... );

    my $domain_transfer = $logic_boxes->get_domain_by_id( ... );
    $logic_boxes->delete_domain_transfer_by_id( $domain_transfer->id );

Given an Integer representing an in progress L<transfer|WWW::LogicBoxes::DomainTransfer>, deletes the specfied domain transfer.  There is a limited amount of time in which you can do this for a new transfer, and you can only do it before the transfer is completed.  If you do this too often then L<LogicBoxes|http://www.logicboxes.com> will get grumpy with you.

=head2 resend_transfer_approval_mail_by_id

    use WWW::LogicBoxes;
    use WWW::LogicBoxes::DomainTransfer;
    use WWW::LogicBoxes::DomainRequest::Transfer;

    my $logic_boxes = WWW::LogicBoxes->new( ... );

    my $domain_transfer = $logic_boxes->get_domain_by_id( ... );
    $logic_boxes->resend_transfer_approval_mail_by_id( $domain_transfer->id );

Given an Integer representing an in progress L<transfer|WWW::LogicBoxes::DomainTransfer> that has not yet been approved by the L<admin contact|WWW::LogicBoxes::Contact> as specified by the losing registrar, will resend the transfer approval email.  If this method is used on a completed transfer, a registration, or a domain that has already been approved this method will croak with an error.

=cut
