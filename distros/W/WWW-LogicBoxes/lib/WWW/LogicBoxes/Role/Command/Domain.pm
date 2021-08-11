package WWW::LogicBoxes::Role::Command::Domain;

use strict;
use warnings;

use Moose::Role;
use MooseX::Params::Validate;

use WWW::LogicBoxes::Types qw( Bool DomainName DomainNames Int InvoiceOption PrivateNameServer Str );

use WWW::LogicBoxes::Domain::Factory;

use Try::Tiny;
use Carp;

use Readonly;
Readonly my $DOMAIN_DETAIL_OPTIONS => [qw( All )];

requires 'submit';

our $VERSION = '1.11.0'; # VERSION
# ABSTRACT: Domain API Calls

sub get_domain_by_id {
    my $self = shift;
    my ( $domain_id ) = pos_validated_list( \@_, { isa => Int } );

    return try {
        my $response = $self->submit({
            method => 'domains__details',
            params => {
                'order-id' => $domain_id,
                'options'  => $DOMAIN_DETAIL_OPTIONS,
            }
        });

        return WWW::LogicBoxes::Domain::Factory->construct_from_response( $response );
    }
    catch {
        if( $_ =~ m/^No Entity found for Entityid/ ) {
            return;
        }

        croak $_;
    };
}

sub get_domain_by_name {
    my $self = shift;
    my ( $domain_name ) = pos_validated_list( \@_, { isa => DomainName } );

    return try {
        my $response = $self->submit({
            method => 'domains__details_by_name',
            params => {
                'domain-name' => $domain_name,
                'options'     => $DOMAIN_DETAIL_OPTIONS,
            }
        });

        return WWW::LogicBoxes::Domain::Factory->construct_from_response( $response );
    }
    catch {
        if( $_ =~ m/^Website doesn't exist for/ ) {
            return;
        }

        croak $_;
    };
}

sub update_domain_contacts {
    my $self = shift;
    my ( %args ) = validated_hash(
        \@_,
        id                    => { isa => Int },
        is_transfer_locked    => { isa => Bool, default => 1 },
        registrant_contact_id => { isa => Int, optional => 1 },
        admin_contact_id      => { isa => Int, optional => 1 },
        technical_contact_id  => { isa => Int, optional => 1 },
        billing_contact_id    => { isa => Int, optional => 1 },
    );

    return try {
        my $original_domain = $self->get_domain_by_id( $args{id} );

        if( !$original_domain ) {
            croak 'No such domain exists';
        }

        my $contact_mapping = {
            registrant_contact_id => 'reg-contact-id',
            admin_contact_id      => 'admin-contact-id',
            technical_contact_id  => 'tech-contact-id',
            billing_contact_id    => 'billing-contact-id',
        };

        my $num_changes = 0;
        my $contacts_to_update;
        for my $contact_type ( keys %{ $contact_mapping } ) {
            if( $args{$contact_type} && $args{$contact_type} != $original_domain->$contact_type ) {
                $contacts_to_update->{ $contact_mapping->{ $contact_type } } = $args{ $contact_type };
                $num_changes++;
            }
            else {
                $contacts_to_update->{ $contact_mapping->{ $contact_type } } = $original_domain->$contact_type;
            }
        }

        if( $num_changes == 0 ) {
            return $original_domain;
        }

        # The not for irtp_lock is because logicboxes treats this as opt out
        # while I'm treating the input as just if it should lock or not
        $self->submit({
            method => 'domains__modify_contact',
            params => {
                'order-id'              => $args{id},
                'sixty-day-lock-optout' => ( !$args{is_transfer_locked} ? 'true' : 'false' ),
                %{ $contacts_to_update }
            }
        });

        return $self->get_domain_by_id( $args{id} );
    }
    catch {
        ## no critic (ControlStructures::ProhibitCascadingIfElse)
        if( $_ =~ m/{registrantcontactid=registrantcontactid is invalid}/ ) {
            croak 'Invalid registrant_contact_id specified';
        }
        elsif( $_ =~ m/{admincontactid=admincontactid is invalid}/ ) {
            croak 'Invalid admin_contact_id specified';
        }
        elsif( $_ =~ m/{techcontactid=techcontactid is invalid}/ ) {
            croak 'Invalid technical_contact_id specified';
        }
        elsif( $_ =~ m/{billingcontactid=billingcontactid is invalid}/ ) {
            croak 'Invalid billing_contact_id specified';
        }
        ## use critic

        croak $_;
    };
}

sub enable_domain_lock_by_id {
    my $self = shift;
    my ( $domain_id ) = pos_validated_list( \@_, { isa => Int } );

    return try {
        $self->submit({
            method => 'domains__enable_theft_protection',
            params => {
                'order-id' => $domain_id,
            }
        });

        return $self->get_domain_by_id( $domain_id );
    }
    catch {
        if( $_ =~ m/^No Entity found for Entityid/ ) {
            croak 'No such domain';
        }

        croak $_;
    };
}

sub disable_domain_lock_by_id {
    my $self = shift;
    my ( $domain_id ) = pos_validated_list( \@_, { isa => Int } );

    return try {
        $self->submit({
            method => 'domains__disable_theft_protection',
            params => {
                'order-id' => $domain_id,
            }
        });

        return $self->get_domain_by_id( $domain_id );
    }
    catch {
        if( $_ =~ m/^No Entity found for Entityid/ ) {
            croak 'No such domain';
        }

        croak $_;
    };
}

sub enable_domain_privacy {
    my $self = shift;
    my ( %args ) = validated_hash(
        \@_,
        id     => { isa => Int },
        reason => { isa => Str, optional => 1 },
    );

    $args{reason} //= 'Enabling Domain Privacy';

    return $self->_set_domain_privacy(
        id     => $args{id},
        status => 1,
        reason => $args{reason},
    );
}

sub disable_domain_privacy {
    my $self = shift;
    my ( %args ) = validated_hash(
        \@_,
        id     => { isa => Int },
        reason => { isa => Str, optional => 1 },
    );

    $args{reason} //= 'Disabling Domain Privacy';

    return try {
        return $self->_set_domain_privacy(
            id     => $args{id},
            status => 0,
            reason => $args{reason},
        );
    }
    catch {
        if( $_ =~ m/^Privacy Protection not Purchased/ ) {
            return $self->get_domain_by_id( $args{id} );
        }

        croak $_;
    };
}

sub _set_domain_privacy {
    my $self = shift;
    my ( %args ) = validated_hash(
        \@_,
        id     => { isa => Int },
        status => { isa => Bool },
        reason => { isa => Str },
    );

    return try {
        $self->submit({
            method => 'domains__modify_privacy_protection',
            params => {
                'order-id'        => $args{id},
                'protect-privacy' => $args{status} ? 'true' : 'false',
                'reason'          => $args{reason},
            }
        });

        return $self->get_domain_by_id( $args{id} );
    }
    catch {
        if( $_ =~ m/^No Entity found for Entityid/ ) {
            croak 'No such domain';
        }

        croak $_;
    };
}

sub update_domain_nameservers {
    my $self = shift;
    my ( %args ) = validated_hash(
        \@_,
        id          => { isa => Int },
        nameservers => { isa => DomainNames },
    );

    return try {
        $self->submit({
            method => 'domains__modify_ns',
            params => {
                'order-id' => $args{id},
                'ns'       => $args{nameservers},
            }
        });

        return $self->get_domain_by_id( $args{id} );
    }
    catch {
        if( $_ =~ m/^No Entity found for Entityid/ ) {
            croak 'No such domain';
        }
        elsif( $_ =~ m/is not a valid Nameserver/ ) {
            croak 'Invalid nameservers provided';
        }
        elsif( $_ =~ m/Same value for new and old NameServers/ ) {
            return $self->get_domain_by_id( $args{id} );
        }

        croak $_;
    };
}

sub renew_domain {
    my $self = shift;
    my ( %args ) = validated_hash(
        \@_,
        id             => { isa => Int },
        years          => { isa => Int },
        is_private     => { isa => Bool, optional => 1 },
        invoice_option => { isa => InvoiceOption, default => 'NoInvoice' },
    );

    return try {
        my $domain = $self->get_domain_by_id( $args{id} );

        if( !$domain ) {
            croak 'No such domain';
        }

        $domain->status eq 'Deleted' and croak 'Domain is already deleted';

        $self->submit({
            method => 'domains__renew',
            params => {
                'order-id'         => $args{id},
                'years'            => $args{years},
                'exp-date'         => $domain->expiration_date->epoch,
                'invoice-option'   =>  $args{invoice_option},
                'purchase-privacy' => $args{is_private} // $domain->is_private,
            }
        });

        return $self->get_domain_by_id( $args{id} );
    }
    catch {
        if( $_ =~ m/^No Entity found for Entityid/ ) {
            croak 'No such domain';
        }
        elsif( $_ =~ m/A Domain Name cannot be extended beyond/ ) {
            croak 'Unable to renew, would violate max registration length';
        }

        croak $_;
    };
}

sub resend_verification_email {
    my $self     = shift;
    my ( %args ) = validated_hash(
        \@_,
        id => { isa => Int },
    );

    return try {
        my $response = $self->submit({
            method => 'domains__details',
            params => {
                'order-id' => $args{id},
                'options'  => 'DomainStatus'
            }
        });

        if( $response->{raaVerificationStatus} eq 'Verified' ){
            croak 'Domain already verified';
        }

        $response = $self->submit({
            method => 'domains__raa__resend_verification',
            params => {
                'order-id' => $args{id}
            }
        });

        return 1 if( $response->{result} eq 'true' );
        return 0 if( $response->{result} eq 'false' );

        croak 'Resend Verification request did not return a result, unknown if sent';
    }
    catch {
        croak 'No matching order found' if( $_ =~ m/You are not allowed to perform this action/ );
        croak 'No such domain'          if( $_ =~ m/No Entity found for Entityid/ );

        croak $_;
    };
}

1;

__END__
=pod

=head1 NAME

WWW::LogicBoxes::Role::Command::Domain - Domain Related Operations

=head1 SYNOPSIS

    use WWW::LogicBoxes;
    use WWW::LogicBoxes::Contact;
    use WWW::LogicBoxes::Domain;

    my $logic_boxes = WWW::LogicBoxes->new( ... );

    # Retrieval
    my $domain = $logic_boxes->get_domain_by_id( 42 );
    my $domain = $logic_boxes->get_domain_by_domain( 'test-domain.com' );

    # Update Contacts
    my $contacts = {
        registrant_contact => WWW::LogicBoxes::Contact->new( ... ),
        admin_contact      => WWW::LogicBoxes::Contact->new( ... ),
        technical_contact  => WWW::LogicBoxes::Contact->new( ... ),
        billing_contact    => WWW::LogicBoxes::Contact->new( ... ),
    };

    $logic_boxes->update_domain_contacts(
        id                    => $domain->id,
        registrant_contact_id => $contacts->{registrant_contact}->id,
        admin_contact_id      => $contacts->{admin_contact}->id,
        technical_contact_id  => $contacts->{technical_contact}->id,
        billing_contact_id    => $contacts->{billing_contact}->id,
    );

    # Domain Locking
    $logic_boxes->enable_domain_lock_by_id( $domain->id );
    $logic_boxes->disable_domain_lock_by_id( $domain->id );

    # Domain Privacy
    $logic_boxes->enable_domain_privacy(
        id     => $domain->id,
        reason => 'Enabling Domain Privacy',
    );

    $logic_boxes->disable_domain_privacy(
        id     => $domain->id,
        reason => 'Disabling Domain Privacy',
    );

    # Nameservers
    $logic_boxes->update_domain_nameservers(
        id          => $domain->id,
        nameservers => [ 'ns1.logicboxes.com', 'ns1.logicboxes.com' ],
    );

    # Renewals
    $logic_boxes->renew_domain(
        id             => $domain->id,
        years          => 1,
        is_private     => 1,
        invoice_option => 'NoInvoice',
    );

=head1 REQUIRES

submit

=head1 DESCRIPTION

Implements domain related operations with the L<LogicBoxes's|http://www.logicboxes.com> API.

=head2 See Also

=over 4

=item For Domain Registration please see L<WWW::LogicBoxes::Role::Command::Domain::Registration>

=item For Domain Availability please see L<WWW::LogicBoxes::Role::Command::Domain::Availability>

=item For Private Nameservers please see L<WWW::LogicBoxes::Role::Command::Domain::PrivateNameServer>

=back

=head1 METHODS

=head2 get_domain_by_id

    use WWW::LogicBoxes;
    use WWW::LogicBoxes::Domain;

    my $logic_boxes = WWW::LogicBoxes->new( ... );
    my $domain      = $logic_boxes->get_domain_by_id( 42 );

Given a Integer L<domain|WWW::LogicBoxes::Domain> id, returns a matching L<WWW::LogicBoxes::Domain> from L<LogicBoxes|http://www.logicobxes.com>.  In the event of no matching L<domain|WWW::LogicBoxes::Domain>, returns undef.

B<NOTE> For domain transfers that are in progress a L<domain_transfer|WWW::LogicBoxes::DomainTransfer> record will be returned.

B<FURTHER NOTE> LogicBoxes is a bit "hand wavey" with "Action Types" which is how this library knows if the domain you are retrieving is an in progress domain transfer or a domain.  Because of this, and the fact that they can be modified at any time, construction of domains defaults to an instance of L<WWW::LogicBoxes::Domain> unless LogicBoxes highlights this as a "AddTransferDomain."  This should just work, but be mindful if you see any unusual or unexpected errors.

=head2 get_domain_by_name

    use WWW::LogicBoxes;
    use WWW::LogicBoxes::Domain;

    my $logic_boxes = WWW::LogicBoxes->new( ... );
    my $domain      = $logic_boxes->get_domain_by_domain( 'test-domain.com' );

Given a full L<domain|WWW::LogicBoxes::Domain> name, returns a matching L<WWW::LogicBoxes::Domain> from L<LogicBoxes|http://www.logicobxes.com>.  In the event of no matching L<domain|WWW::LogicBoxes::Domain>, returns undef,

B<NOTE> For domain transfers that are in progress a L<domain_transfer|WWW::LogicBoxes::DomainTransfer> record will be returned.

B<FURTHER NOTE> See the note above about Action Types

=head2 update_domain_contacts

    use WWW::LogicBoxes;
    use WWW::LogicBoxes::Contact;
    use WWW::LogicBoxes::Domain;

    my $logic_boxes = WWW::LogicBoxes->new( ... );

    # Update Contacts
    my $contacts = {
        registrant_contact => WWW::LogicBoxes::Contact->new( ... ),
        admin_contact      => WWW::LogicBoxes::Contact->new( ... ),
        technical_contact  => WWW::LogicBoxes::Contact->new( ... ),
        billing_contact    => WWW::LogicBoxes::Contact->new( ... ),
    };

    $logic_boxes->update_domain_contacts(
        id                    => $domain->id,
        is_transfer_locked    => 1,            # Optional, defaults to true and only relevant for registrant changes
        registrant_contact_id => $contacts->{registrant_contact}->id,
        admin_contact_id      => $contacts->{admin_contact}->id,
        technical_contact_id  => $contacts->{technical_contact}->id,
        billing_contact_id    => $contacts->{billing_contact}->id,
    );

Given a L<domain|WWW::LogicBoxes::Domain> id and optionally a L<contact|WWW::LogicBoxes::Contact> id for registrant_contact_id, admin_contact_id, technical_contact_id, and/or billing_contact_id, updates the L<domain|WWW::LogicBoxes::Domain> contacts.  Also accepted is an optional is_transfer_locked that indicates if a 60 day lock should be applied to the domain after a change of registrant contact.  This value defaults to true if it's not provided and is only relevant for changes of the registrant contact that trigger the IRTP process.

This method is smart enough to not request a change if the contact hasn't been updated and consumers need only specify the elements that are changing.

=head2 enable_domain_lock_by_id

    use WWW::LogicBoxes;
    use WWW::LogicBoxes::Domain;

    my $logic_boxes = WWW::LogicBoxes->new( ... );
    $logic_boxes->enable_domain_lock_by_id( $domain->id );

Given an Integer L<domain|WWW::LogicBoxes::Domain> id, locks the L<domain|WWW::LogicBoxes::Domain> so that it can not be transfered away.

=head2 disable_domain_lock_by_id

    use WWW::LogicBoxes;
    use WWW::LogicBoxes::Domain;

    my $logic_boxes = WWW::LogicBoxes->new( ... );
    $logic_boxes->disable_domain_lock_by_id( $domain->id );

Given an Integer L<domain|WWW::LogicBoxes::Domain> id, unlocks the L<domain|WWW::LogicBoxes::Domain> so that it can be transfered away.

=head2 enable_domain_privacy

    use WWW::LogicBoxes;
    use WWW::LogicBoxes::Domain;

    my $logic_boxes = WWW::LogicBoxes->new( ... );
    $logic_boxes->enable_domain_privacy(
        id     => $domain->id,
        reason => 'Enabling Domain Privacy',
    );

Given an Integer L<domain|WWW::LogicBoxes::Domain> id and an optional reason ( defaults to "Enabling Domain Privacy" ), enables WHOIS Privacy Protect for the L<domain|WWW::LogicBoxes::Domain>.

=head2 disable_domain_privacy

    use WWW::LogicBoxes;
    use WWW::LogicBoxes::Domain;

    my $logic_boxes = WWW::LogicBoxes->new( ... );
    $logic_boxes->disable_domain_privacy(
        id     => $domain->id,
        reason => 'Disabling Domain Privacy',
    );

Given an Integer L<domain|WWW::LogicBoxes::Domain> id and an optional reason ( defaults to "Disabling Domain Privacy" ), disabled WHOIS Privacy Protect for the L<domain|WWW::LogicBoxes::Domain>.

=head2 update_domain_nameservers

    use WWW::LogicBoxes;
    use WWW::LogicBoxes::Domain;

    my $logic_boxes = WWW::LogicBoxes->new( ... );
    $logic_boxes->update_domain_nameservers(
        id          => $domain->id,
        nameservers => [ 'ns1.logicboxes.com', 'ns1.logicboxes.com' ],
    );

Given an Integer L<domain|WWW::LogicBoxes::Domain> id and an ArrayRef of nameserver hostnames, sets the L<domain|WWW::LogicBoxes::Domain>'s authoritative nameservers.

=head2 renew_domain

    use WWW::LogicBoxes;
    use WWW::LogicBooxes::Domain;

    my $logic_boxes = WWW::LogicBoxes->new( ... );
    $logic_boxes->renew_domain(
        id             => $domain->id,
        years          => 1,
        is_private     => 1,
        invoice_option => 'NoInvoice',
    );

Extends the registration term for the specified domain by the specified number of years.  Note, there is a limit as to how far into the future the expiration_date can be and it's specific to each TLD, see L<http://manage.logicboxes.com/kb/servlet/KBServlet/faq1375.html> for details.

Arguments:

=over 4

=item id

The domain id to renew

=item years

The number of years

=item is_private

This is optional, if not specified then the current privacy status of the domain will be used.  If there is no charge for domain privacy in your reseller panel then this field doesn't really matter.  However, if there is a cost for it and you don't pass is_private => 1 then the domain privacy will be cancelled since it's term will not match the registration term.

=item invoice_option

See L<WWW::LogicBoxes::DomainRequest/invoice_option> for additional details about Invoicing Options.  Defaults to NoInvoice.

=back

Returns an instance of the domain object.

=head2 resend_verification_email

    use WWW::LogicBoxes;
    use WWW::LogicBooxes::Domain;

    my $logic_boxes = WWW::LogicBoxes->new( ... );
    $logic_boxes->resend_verification_email( id => $domain->id );

Given an Integer L<domain|WWW::LogicBoxes::Domain> id, resends Verification email. Returns truthy if executed successfully or falsey if not.  Will croak if unable to determine if the resend was successful.

=cut
