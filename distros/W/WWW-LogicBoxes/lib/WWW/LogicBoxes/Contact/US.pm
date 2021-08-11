package WWW::LogicBoxes::Contact::US;

use strict;
use warnings;

use Moose;
use MooseX::StrictConstructor;
use namespace::autoclean;

use WWW::LogicBoxes::Types qw( NexusPurpose NexusCategory );

extends 'WWW::LogicBoxes::Contact';

our $VERSION = '1.11.0'; # VERSION
# ABSTRACT: Contact for .US Registrations

has 'nexus_purpose' => (
    is       => 'ro',
    isa      => NexusPurpose,
    required => 1,
);

has 'nexus_category' => (
    is       => 'ro',
    isa      => NexusCategory,
    required => 1,
);

sub construct_creation_request {
    my $self = shift;

    my $request = $self->SUPER::construct_creation_request();

    $request->{'attr-name1'}  = 'purpose';
    $request->{'attr-value1'} = $self->nexus_purpose;

    $request->{'attr-name2'}  = 'category';
    $request->{'attr-value2'} = $self->nexus_category;

    return $request;
}

sub construct_from_response {
    my $self = shift;
    my $response = shift;

    if( !defined $response ) {
        return;
    }

    my $contact = WWW::LogicBoxes::Contact->construct_from_response( $response );

    if( !defined $contact ) {
        return;
    }

    $self->meta->rebless_instance( $contact,
        nexus_purpose  => $response->{ApplicationPurpose},
        nexus_category => $response->{NexusCategory},
    );

    return $contact;
}

__PACKAGE__->meta->make_immutable;
1;

__END__
=pod

=head1 NAME

WWW::LogicBoxes::Contact::US - Representation of Domain Contact for .us Domains

=head1 SYNOPSIS

    use strict;
    use warnings;

    use WWW::LogicBoxes::Customer;
    use WWW::LogicBoxes::Contact::US;

    my $customer = WWW::LogicBoxes::Customer->new( ... ); # Valid LogicBoxes Customer

    my $contact = WWW::LogicBoxes::Contact::US->new(
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
        type         => 'Contact',
        customer_id  => $customer->id,

        nexus_purpose  => 'P1',
        nexus_category => 'C11',
    );

=head1 EXTENDS

L<WWW::LogicBoxes::Contact>

=head1 DESCRIPTION

Representation of a L<LogicBoxes|http://www.logicboxes.com> domain contact for .us TLD domains.  The .us tld is special in that specific L<Nexus Data|http://www.neustar.us/the-ustld-nexus-requirements/> must be provided.

=head1 ATTRIBUTES

All of the existing L<WWW::LogicBoxes::Contact> attributes remain unchanged with two new attributes.  The description for these values is taken from L<http://www.whois.us/whois-gui/US/faqs.html>.

=head2 B<nexus_purpose>

This is the B<Domain Name Application Purpose Code>, the reason this domain was registered and a bit about it's intended usage.

Must be one of the following I<2 character> values:

=over 4

=item P1 - Business use for profit.

=item P2 - Non-profit business, club, association, religious organization, etc.

=item P3 - Personal use.

=item P4 - Education purposes.

=item P5 - Government purposes

=back

=head2 B<nexus_category>

This is the B<Nexus Code>, it contains information about the contact and their relationship with respect to US residency.

Must be one of the following I<2 character> values:

=over 4

=item C11 - A natural person who is a United States citizen.

=item C12 - A natural person who is a permanent resident of the United States of America, or any of its possessions or territories.

=item C21 - A US-based organization or company (A US-based organization or company formed within one of the fifty (50) U.S. states, the District of Columbia, or any of the United States possessions or territories, or organized or otherwise constituted under the laws of a state of the United States of America, the District of Columbia or any of its possessions or territories or a U.S. federal, state, or local government entity or a political subdivision thereof).

=item C31 - A foreign entity or organization (A foreign entity or organization that has a bona fide presence in the United States of America or any of its possessions or territories who regularly engages in lawful activities (sales of goods or services or other business, commercial or non-commercial, including not-for-profit relations in the United States)).

=item C32 - Entity has an office or other facility in the United States.

=back

=cut
