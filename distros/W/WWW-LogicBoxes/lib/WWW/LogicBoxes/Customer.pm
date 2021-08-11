package WWW::LogicBoxes::Customer;

use strict;
use warnings;

use Moose;
use Moose::Util::TypeConstraints;
use MooseX::StrictConstructor;
use namespace::autoclean;

use WWW::LogicBoxes::Types qw(EmailAddress Int Language PhoneNumber Str );

use WWW::LogicBoxes::PhoneNumber;

our $VERSION = '1.11.0'; # VERSION
# ABSTRACT: LogicBoxes Customer

has 'id' => (
    is        => 'ro',
    isa       => Int,
    required  => 0,
    predicate => 'has_id',
    writer    => '_set_id',
);

has 'username' => (
    is       => 'ro',
    isa      => EmailAddress,
    required => 1,
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

has 'alt_phone_number' => (
    is        => 'ro',
    isa       => PhoneNumber,
    required  => 0,
    coerce    => 1,
    predicate => 'has_alt_phone_number',
);

has 'mobile_phone_number' => (
    is        => 'ro',
    isa       => PhoneNumber,
    required  => 0,
    coerce    => 1,
    predicate => 'has_mobile_phone_number',
);

has 'fax_number' => (
    is        => 'ro',
    isa       => PhoneNumber,
    required  => 0,
    coerce    => 1,
    predicate => 'has_fax_number',
);

has 'language_preference' => (
    is       => 'ro',
    isa      => Language,
    default  => 'en',
);

sub construct_from_response {
    my $self     = shift;
    my $response = shift;

    if(!defined $response) {
        return;
    }

    return $self->new({
        id       => $response->{customerid},
        username => $response->{username},
        name     => $response->{name},
        company  => $response->{company},
        address1 => $response->{address1},
        ( exists $response->{address2} ) ? ( address2 => $response->{address2} ) : ( ),
        ( exists $response->{address3} ) ? ( address3 => $response->{address3} ) : ( ),
        city     => $response->{city},
        ( $response->{state} ne 'Not Applicable' ) ? ( state => $response->{state} ) : ( ),
        country  => $response->{country},
        zipcode  => $response->{zip},
        phone_number => ( $response->{telnocc} . $response->{telno} ),
        ( exists $response->{faxnocc} )
            ? ( fax_number => ( $response->{faxnocc} . $response->{faxno} ) )
            : ( ),
        ( exists $response->{mobilenocc} )
            ? ( mobile_phone_number => ( $response->{mobilenocc} . $response->{mobileno} ) )
            : ( ),
        ( exists $response->{alttelnocc} )
            ? ( alt_phone_number => ( $response->{alttelnocc} . $response->{alttelno} ) )
            : ( ),
        language_preference => $response->{langpref},
    });
}

__PACKAGE__->meta->make_immutable;

1;

__END__
=pod

=head1 NAME

WWW::LogicBoxes::Customer - Representation of LogicBoxes Customer

=head1 SYNOPSIS

    use strict;
    use warnings;

    use WWW::LogicBoxes::Customer;

    my $customer = WWW::LogicBoxes::Customer->new(
        id       => 42,
        username => 'alan.turing@enigma-crackers.com',
        name     => 'Alan Turing',
        company  => 'Princeton University',
        address1 => 'Office P is Equal to NP',
        address2 => '123 Turing Machine Way',
        address3 => 'Suite 100',
        city     => 'New York',
        state    => 'New York',
        country  => 'US',
        zipcode  => '10108',
        phone_number        => '18005551212',
        alt_phone_number    => '18005551212',
        mobile_phone_number => '18005551212',
        fax_number          => '18005551212',
        language_preference => 'en',
    );

=head1 DESCRIPTION

Representation of a L<LogicBoxes|http://www.logicobxes.com> customer.

=head1 ATTRIBUTES

=head2 id

Customers that have been created with LogicBoxes will have an id assigned for them.  A predicate exists 'has_id' that can be used to check to see if an id has been assigned to this customer.  A private writer of _set_id is also provided.

=head2 B<username>

Email address for customer.

=head2 B<name>

=head2 B<company>

Company of the customer.  This is a required field so if there is no company some sentinal string of "None" or something similiar shou  ld be used.

=head2 B<address1>

=head2 address2

Predicate of has_address2.

=head2 address3

Predicate of has_address3.

=head2 B<city>

=head2 state

This is the full name of the state, so Texas rather than TX should be used.  Not all regions in the world have states so this is not   a required field, a predicate of has_state exists.

=head2 B<country>

The ISO-3166 code for the country.  For more information on ISO-3166 please see L<Wikipedia|https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2>.

=head2 B<zipcode>

=head2 B<phone_number>

Be sure to include the country code.  When it comes to the phone number a string or L<Number::Phone> object can be provided and it wi  ll be coerced into the L<WWW::LogicBoxes::PhoneNumber> internal representation used.

=head2 alt_phone_number

Predicate of has_alt_phone_number.

=head2 mobile_phone_number

Predicate of has_mobile_phone_number.

=head2 fax_number

Predicate of has_fax_number.

=head2 language_preference

The default language to use for messages that are displayed to customers if they log directly into L<LogicBoxes|http://www.logicboxes.com>.  This must be an ISO-639-1 two digit language code as detailed in L<https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes>.  The default is en for English.

If you have fully abstracted LogicBoxes for your customers and they never log in directly to manage their domains then this value doesn't really matter.

=head1 METHODS

These methods are used internally, it's fairly unlikely that consumers will ever call them directly.

=head2 construct_from_response

    my $logic_boxes = WWW::LogicBoxes->new( ... );

    my $response = $logic_boxes->submit({
        method => 'customers__details_by_id',
        params => {
            'customer-id' => 42,
        }
    });

    my $customer = WWW::LogicBoxes::Customer->construct_from_response( $response );

Creates an instance of $self from a L<LogicBoxes|http://www.logicbox.com> response.

=cut
