package WWW::LogicBoxes::Contact;

use strict;
use warnings;

use Moose;
use MooseX::StrictConstructor;
use namespace::autoclean;

use WWW::LogicBoxes::Types qw(Int Str EmailAddress PhoneNumber ContactType);

use WWW::LogicBoxes::PhoneNumber;

our $VERSION = '1.10.0'; # VERSION
# ABSTRACT: LogicBoxes Contact

has 'id' => (
    is        => 'ro',
    isa       => Int,
    required  => 0,
    predicate => 'has_id',
    writer    => '_set_id',
);

has 'name' => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has 'company' => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has 'email' => (
    is       => 'ro',
    isa      => EmailAddress,
    required => 1,
);

has 'address1' => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has 'address2' => (
    is        => 'ro',
    isa       => Str,
    required  => 0,
    predicate => 'has_address2',
);

has 'address3' => (
    is        => 'ro',
    isa       => Str,
    required  => 0,
    predicate => 'has_address3',
);

has 'city' => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has 'state' => (
    is        => 'ro',
    isa       => Str,
    required  => 0,
    predicate => 'has_state',
);

has 'country' => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has 'zipcode' => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has 'phone_number' => (
    is       => 'ro',
    isa      => PhoneNumber,
    required => 1,
    coerce   => 1,
);

has 'fax_number' => (
    is        => 'ro',
    isa       => PhoneNumber,
    required  => 0,
    coerce    => 1,
    predicate => 'has_fax_number',
);

has 'type' => (
    is       => 'ro',
    isa      => ContactType,
    required => 0,
    default  => 'Contact',
);

has 'customer_id' => (
    is       => 'ro',
    isa      => Int,
    required => 1,
);

sub construct_creation_request {
    my $self = shift;

    return {
        name          => $self->name,
        company       => $self->company,
        email         => $self->email,

        'address-line-1' => $self->address1,
        ( $self->has_address2 ) ? ( 'address-line-2' => $self->address2 ) : ( ),
        ( $self->has_address3 ) ? ( 'address-line-3' => $self->address3 ) : ( ),
        city          => $self->city,
        ( $self->has_state )    ? ( state => $self->state ) : ( ),
        country       => $self->country,
        zipcode       => $self->zipcode,

        'phone-cc'    => $self->phone_number->country_code,
        phone         => $self->phone_number->number,
        ( $self->has_fax_number )
            ? ('fax-cc'      => $self->fax_number->country_code,
                fax          => $self->fax_number->number,
            ) : ( ),

        type          => $self->type,
        'customer-id' => $self->customer_id,
    };
}

sub construct_from_response {
    my $self     = shift;
    my $response = shift;

    if(!defined $response) {
        return;
    }

    if( $response->{currentstatus} eq 'Deleted' ) {
        return;
    }

    my $contact = $self->new({
        id         => $response->{contactid},
        name       => $response->{name},
        company    => $response->{company},
        email      => $response->{emailaddr},

        address1   => $response->{address1},
        ( exists $response->{address2} ) ? ( address2 => $response->{address2} ) : ( ),
        ( exists $response->{address3} ) ? ( address3 => $response->{address3} ) : ( ),
        city       => $response->{city},
        ( exists $response->{state}    ) ? ( state    => $response->{state}    ) : ( ),
        country    => $response->{country},
        zipcode    => $response->{zip},

        phone_number => ( $response->{telnocc} . $response->{telno} ),
        ( exists $response->{faxnocc} )
            ? ( fax_number => ( $response->{faxnocc} . $response->{faxno} ) )
            : ( ),

        type        => $response->{type},
        customer_id => $response->{customerid},
    });

    return $contact;
}

__PACKAGE__->meta->make_immutable;

1;

__END__
=pod

=head1 NAME

WWW::LogicBoxes::Contact - Representation of Domain Contact

=head1 SYNOPSIS

    use strict;
    use warnings;

    use WWW::LogicBoxes::Customer;
    use WWW::LogicBoxes::Contact;

    my $customer = WWW::LogicBoxes::Customer->new( ... ); # Valid LogicBoxes Customer

    my $contact = WWW::LogicBoxes::Contact->new(
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
    );

=head1 DESCRIPTION

Representation of a L<LogicBoxes|http://www.logicboxes.com> domain contact.

=head1 ATTRIBUTES

=head2 id

Contacts that have actually been created will have an id assigned for them.  A predicate exists 'has_id' that can be used to check to see if an id has been assigned to this contact.  A private writer of _set_id is also provided.

=head2 B<name>

=head2 B<company>

Company of the contact.  This is a required field so if there is no company some sentinal string of "None" or something similiar should be used.

=head2 B<email>

=head2 B<address1>

=head2 address2

Predicate of has_address2.

=head2 address3

Predicate of has_address3.

=head2 B<city>

=head2 state

This is the full name of the state, so Texas rather than TX should be used.  Not all regions in the world have states so this is not a required field, a predicate of has_state exists.

=head2 B<country>

The ISO-3166 code for the country.  For more information on ISO-3166 please see L<Wikipedia|https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2>.

=head2 B<zipcode>

=head2 B<phone_number>

Be sure to include the country code.  When it comes to the phone number a string or L<Number::Phone> object can be provided and it will be coerced into the L<WWW::LogicBoxes::PhoneNumber> internal representation used.

=head2 fax_number

Predicate of has_fax_number

=head2 type

The type of contact, B<NOT TO BE CONFUSED> with what this contact is being used for on a domain.  This B<IS NOT> Registrant, Billing, Admin, or Technical.  The default value is 'Contact' and you almost never want to change this.

=head2 B<customer_id>

The id of the customer that this contact is assoicated with.

=head1 METHODS

These methods are used internally, it's fairly unlikely that consumers will ever call them directly.

=head2 construct_creation_request

    my $logic_boxes = WWW::LogicBoxes->new( ... );
    my $contact     = WWW::LogicBoxes::Contact->new( ... );

    my $response = $logic_boxes->submit({
        method => 'contacts__add',
        params => $contact->construct_creation_request(),
    });

Converts $self into a HashRef suitable for creation of a contact with L<LogicBoxes|http://www.logicboxes.com>

=head2 construct_from_response

    my $logic_boxes = WWW::LogicBoxes->new( ... );

    my $response = $logic_boxes->submit({
        method => 'contacts__details',
        params => {
            'contact-id' => 42,
        }
    });

    my $contact = WWW::LogicBoxes::Contact->construct_from_response( $response );

Creates an instance of $self from a L<LogicBoxes|http://www.logicboxes.com> response.

=head1 SEE ALSO

For .us domains L<WWW::LogicBoxes::Contact::US> must be used for at least the registrant contact.

=cut
