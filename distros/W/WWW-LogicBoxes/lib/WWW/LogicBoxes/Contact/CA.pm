package WWW::LogicBoxes::Contact::CA;

use strict;
use warnings;

use Moose;
use MooseX::StrictConstructor;
use namespace::autoclean;

use WWW::LogicBoxes::Types qw( CPR CPRIndividual CPRNonIndividual Str );

use Carp;

extends 'WWW::LogicBoxes::Contact';

our $VERSION = '1.10.0'; # VERSION
# ABSTRACT: Contact for .CA Registrations

has '+type' => (
    default  => 'CaContact',
);

has 'cpr' => (
    is       => 'ro',
    isa      => CPR,
    required => 1,
);

has 'agreement_version' => (
    is        => 'ro',
    isa       => Str,
    required  => 0,
    predicate => 'has_agreement_version',
);

sub BUILD {
    my $self = shift;

    if( $self->type ne 'CaContact' ) {
        croak 'CA Contacts must have a type of CaContact';
    }

    if( !$self->has_id && !$self->has_agreement_version ) {
        croak 'An agreement_version must be provided for new CA Contacts';
    }

    if( grep { $_ eq $self->cpr } @{ CPRNonIndividual->values } && $self->company ne 'N/A' ) {
        croak 'For Non Individual CA Contacts the company must be "N/A"';
    }

    return $self;
}

sub construct_creation_request {
    my $self = shift;

    my $request = $self->SUPER::construct_creation_request();

    $request->{'attr-name1'}  = 'CPR';
    $request->{'attr-value1'} = $self->cpr;

    if( $self->has_agreement_version ) {
        $request->{'attr-name2'}  = 'AgreementVersion';
        $request->{'attr-value2'} = $self->agreement_version;

        $request->{'attr-name3'}  = 'AgreementValue';
        $request->{'attr-value3'} = 'y';
    }

    return $request;
}

sub construct_from_response {
    my $self     = shift;
    my $response = shift;

    if( !defined $response ) {
        return;
    }

    my $contact = WWW::LogicBoxes::Contact->construct_from_response( $response );

    if( !defined $contact ) {
        return;
    }

    $self->meta->rebless_instance( $contact,
        cpr => $response->{CPR},
    );

    return $contact;
}

__PACKAGE__->meta->make_immutable;
1;

__END__
=pod

=head1 NAME

WWW::LogicBoxes::Contact::CA - Representation of Domain Contact for .ca Domains

=head1 SYNOPSIS

    use strict;
    use warnings;

    use WWW::LogicBoxes;
    use WWW::LogicBoxes::Customer;
    use WWW::LogicBoxes::Contact::CA;
    use WWW::LogicBoxes::Contact::CA::Agreement;

    my $api       = WWW::LogicBoxes->new( ... );
    my $agreement = $api->get_ca_registrant_contact();

    my $customer  = WWW::LogicBoxes::Customer->new( ... ); # Valid LogicBoxes Customer

    my $contact = WWW::LogicBoxes::Contact::CA->new(
        id           => 42,
        name         => 'Edsger Dijkstra',
        company      => 'University of Texas at Austin',
        email        => 'depth.first@search.com',
        address1     => 'University of Texas',
        address2     => '42 Main St',
        city         => 'Austin',
        state        => 'Texas',
        country      => 'US',
        zipcode      => '78713',
        phone_number => '18005551212',
        fax_number   => '18005551212',
        customer_id  => $customer->id,

        cpr               => 'RES',
        agreement_version => $agreement->version,
    );

=head1 EXTENDS

L<WWW::LogicBoxes::Contact>

=head1 DESCRIPTION

Representation of a L<LogicBoxes|http://www.logicboxes.com> domain contact for .ca TLD domains.  The .ca TLD is special in that specific CPR and Agreement data must be provided.  For details on the agreement that customers must accept please see L<WWW::LogicBoxes::Contact::CA::Agreement>.

=head1 ATTRIBUTES

=head2 B<name>

The name has special restrictions based on if the CPR provided is for Individuals or Non Individuals.  Please see L<http://manage.logicboxes.com/kb/sites/default/files/Valid%20Contact%20Names.pdf> for a full listing of key words that must or must not be present.

Also, the name of a CA Contact can not be changed!  If you really need to change it, you'll have to create a whole new L<WWW::LogicBoxes::Contact::CA> with the desired information, replace it on any domain that uses the old contact, and then delete the old contact.

=head2 B<cpr>

Similiar to nexus_data for .us domains, the CPR is a specialized code that describes the registrant contact.  It must take on one of the following values (original source L<http://manage.logicboxes.com/kb/answer/790>):

=head3 CPR For Individuals

=over 4

=item ABO - Aboriginal Peoples (individuals or groups) indigenous to Canada

=item CCT - Canadian citizen

=item LGR - Legal Representative of a Canadian Citizen or Permanent Resident

=item RES - Permanent Resident of Canada

=back

=head3 CPR For Non Individuals

B<NOTE> For Non Individual CPRs the company name MUST be "N/A".

=over 4

=item ASS Canadian Unincorporated Association

=item CCO Corporation (Canada or Canadian province or territory)

=item EDU Canadian Educational institution

=item GOV Government or government entity in Canada

=item HOP Canadian Hospital

=item INB Indian Band recognized by the Indian Act of Canada

=item LAM Canadian Library, Archive or Museum

=item MAJ Her Majesty the Queen

=item OMK Official mark registered in Canada

=item PLT Canadian Political Party

=item PRT Partnership Registered in Canada

=item TDM Trade-mark registered in Canada (by a non-Canadian owner)

=item TRD Canadian Trade Union

=item TRS Trust established in Canada

=back

The cpr B<can not be changed> once the contact is created.

=head2 agreement_version

The version of the CA Registrant Agreement the customer is accepting (retrieved via L<WWW::LogicBoxes::Role::Command::Contact/get_ca_registrant_agreement> which returns a L<WWW::LogicBoxes::Contact::CA::Agreement>).  This value must be specified when creating a new contact but is never returned by the API.

Offers a predicate of has_agreement_version.

=cut
