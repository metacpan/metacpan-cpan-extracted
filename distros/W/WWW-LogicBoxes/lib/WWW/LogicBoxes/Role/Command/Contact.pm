package WWW::LogicBoxes::Role::Command::Contact;

use strict;
use warnings;

use Moose::Role;
use MooseX::Params::Validate;

use WWW::LogicBoxes::Types qw( Contact Int );

use WWW::LogicBoxes::Contact::CA::Agreement;
use WWW::LogicBoxes::Contact::Factory;

use Try::Tiny;
use Carp;

use Readonly;
Readonly our $UPDATE_CONTACT_OBSOLETE => 'Due to IRTP Regulations, as of 2016-12-01 it is no longer possible to update contacts.  Instead, you should create a new contact and then assoicate this new contact with the domain whose contact you wish to change';

requires 'submit';

our $VERSION = '1.9.0'; # VERSION
# ABSTRACT: Contact API Calls

sub create_contact {
    my $self   = shift;
    my (%args) = validated_hash(
        \@_,
        contact => { isa => Contact, coerce => 1 },
    );

    if( $args{contact}->has_id ) {
        croak "Contact already exists (it has an id)";
    }

    my $response = $self->submit({
        method => 'contacts__add',
        params => $args{contact}->construct_creation_request(),
    });

    $args{contact}->_set_id($response->{id});

    return $args{contact};
}

sub get_contact_by_id {
    my $self = shift;
    my ( $id ) = pos_validated_list( \@_, { isa => Int } );

    return try {
        my $response = $self->submit({
            method => 'contacts__details',
            params => {
                'contact-id' => $id,
            },
        });

        return WWW::LogicBoxes::Contact::Factory->construct_from_response( $response );
    }
    catch {
        if( $_ =~ m/^Invalid contact-id/ || $_ =~ m/^No Entity found/ ) {
            return;
        }

        croak $_;
    };
}

sub update_contact {
    croak $UPDATE_CONTACT_OBSOLETE;
}

sub delete_contact_by_id {
    my $self = shift;
    my ( $id ) = pos_validated_list( \@_, { isa => Int } );

    return try {
        $self->submit({
            method => 'contacts__delete',
            params => {
                'contact-id' => $id,
            },
        });

        return;
    }
    catch {
        croak $_;
    };
}

sub get_ca_registrant_agreement {
    my $self   = shift;

    return try {
        my $response = $self->submit({
            method => 'contacts__dotca__registrantagreement',
        });

        return WWW::LogicBoxes::Contact::CA::Agreement->new(
            version => $response->{version},
            content => $response->{agreement},
        );
    }
    catch {
        croak $_;
    };
}

1;

__END__
=pod

=head1 NAME

WWW::LogicBoxes::Role::Command::Contact - Contact Related Operations

=head1 SYNOPSIS

    use WWW::LogicBoxes;
    use WWW::LogicBoxes::Customer;
    use WWW::LogicBoxes::Contact;

    my $customer = WWW::LogicBoxes::Customer->new( ... );
    my $contact  = WWW::LogicBoxes::Contact->new( ... );

    # Creation
    my $logic_boxes = WWW::LogicBoxes->new( ... );
    $logic_boxes->create_contact( contact => $contact );

    # Retrieval
    my $retrieved_contact = $logic_boxes->get_contact_by_id( $contact->id );

    # Update
    # UPDATE IS OBSOLETE AND NO LONGER SUPPORTED! ( See POD )

    # Deletion
    $logic_boxes->delete_contact_by_id( $contact->id );

    # CA Registrant Agreement
    my $agreement = $logic_boxes->get_ca_registrant_agreement();

=head1 REQURIES

submit

=head1 DESCRIPTION

Implements contact related operations with the L<LogicBoxes's|http://www.logicboxes.com> API.

=head1 METHODS

=head2 create_contact

    use WWW::LogicBoxes;
    use WWW::LogicBoxes::Customer;
    use WWW::LogicBoxes::Contact;

    my $customer = WWW::LogicBoxes::Customer->new( ... );
    my $contact  = WWW::LogicBoxes::Contact->new( ... );

    my $logic_boxes = WWW::LogicBoxes->new( ... );
    $logic_boxes->create_contact( contact => $contact );

    print 'New contact id: ' . $contact->id . "\n";

Given a L<WWW::LogicBoxes::Contact> or a HashRef that can be coerced into a L<WWW::LogicBoxes::Contact>, creates the specified contact with LogicBoxes.

=head2 get_contact_by_id

    use WWW::LogicBoxes;
    use WWW::LogicBoxes::Contact;

    my $logic_boxes = WWW::LogicBoxes->new( ... );
    my $contact     = $logic_boxes->get_contact_by_id( 42 );

Given an Integer ID, will return an instance of L<WWW::LogicBoxes::Contact> (or one of it's subclass for specialized contacts).  Returns undef if there is no matching L<contact|WWW::LogicBoxes::Contact> with the specified id.

=head2 update_contact

    OBSOLETE!

On 2016-12-01, a new L<ICANN Inter Registrar Transfer Policy|https://www.icann.org/resources/pages/transfer-policy-2016-06-01-en> went into effect.  LogicBoxes is complying with this by not permitting modification of contacts any longer.

Instead, if you wish to update a contact, you should do the following:

=over 4

=item 1. Create a New Contact - L<create_contact|WWW::LogicBoxes::Role::Command::Contact/create_contact>

=item 2. Assign That Contact To The Domain - L<update_domain_contacts|WWW::LogicBoxes::Role::Command::Domain/update_domain_contacts>

=item 3. (Optionally) Delete the previous contact after the changes are approved - L<delete_contact_by_id|WWW::LogicBoxes::Role::Command::Contact/delete_contact_by_id>

=back

=head2 delete_contact_by_id

    use WWW::LogicBoxes;
    use WWW::LogicBoxes::Contact;

    my $logic_boxes = WWW::LogicBoxes->new( ... );
    $logic_boxes->delete_contact_by_id( 42 );

Given an Integer ID, will delete the L<contact|WWW::LogicBoxes::Contact> with L<LogicBoxes|http://www.logicboxes.com>.

This method will croak if the contact is in use (assigned to a domain).

=head2 get_ca_registrant_agreement

    use WWW::LogicBoxes;
    use WWW::LogicBoxes::Contact;

    my $logic_boxes = WWW::LogicBoxes->new( ... );
    my $agreement = $logic_boxes->get_ca_registrant_agreement();

Accepts no arguments, returns an instance of L<WWW::LogicBoxes::Contact::CA::Agreement> that describes the currently active and required CA Registrant Agreement.

B<Note> Registrants are required to accept this agreement in order to register a .ca domain.

=cut
