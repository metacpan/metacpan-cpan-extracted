package WWW::LogicBoxes::Role::Command::Customer;

use strict;
use warnings;

use Moose::Role;
use MooseX::Params::Validate;

use WWW::LogicBoxes::Types qw( Customer EmailAddress Int Password );

use WWW::LogicBoxes::Customer;

use Try::Tiny;
use Carp;

requires 'submit';

our $VERSION = '1.9.0'; # VERSION
# ABSTRACT: Customer API Calls

sub create_customer {
    my $self = shift;
    my ( %args ) = validated_hash(
        \@_,
        customer => { isa => Customer, coerce => 1 },
        password => { isa => Password },
    );

    if( $args{customer}->has_id ) {
        croak "Customer already exists (it has an id)";
    }

    my $response = $self->submit({
        method => 'customers__signup',
        params => {
            username => $args{customer}->username,
            passwd   => $args{password},
            name     => $args{customer}->name,
            company  => $args{customer}->company,

            'address-line-1' => $args{customer}->address1,
            ( $args{customer}->has_address2 ) ? ( 'address-line-2' => $args{customer}->address2 ) : ( ),
            ( $args{customer}->has_address3 ) ? ( 'address-line-3' => $args{customer}->address3 ) : ( ),

            city          => $args{customer}->city,
            ( $args{customer}->has_state ) ? ( state => $args{customer}->state ) : ( state => 'Not Applicable', 'other-state' => ''),
            country       => $args{customer}->country,
            zipcode       => $args{customer}->zipcode,

            'phone-cc'    => $args{customer}->phone_number->country_code,
            'phone'       => $args{customer}->phone_number->number,
            ($args{customer}->has_fax_number) ?
                (   'fax-cc'      => $args{customer}->fax_number->country_code,
                    'fax'         => $args{customer}->fax_number->number,
                ) : (),
            ($args{customer}->has_alt_phone_number) ?
                (   'alt-phone-cc'      => $args{customer}->alt_phone_number->country_code,
                    'alt-phone'         => $args{customer}->alt_phone_number->number,
                ) : (),
            ($args{customer}->has_mobile_phone_number) ?
                (   'mobile-cc'      => $args{customer}->mobile_phone_number->country_code,
                    'mobile'         => $args{customer}->mobile_phone_number->number,
                ) : (),

            'lang-pref'   => $args{customer}->language_preference,
        },
    });

    $args{customer}->_set_id( $response->{id} );

    return $args{customer};
}

sub get_customer_by_id {
    my $self        = shift;
    my ( $customer_id ) = pos_validated_list( \@_, { isa => Int } );

    return try {
        my $response = $self->submit({
            method => 'customers__details_by_id',
            params => {
                'customer-id' => $customer_id,
            }
        });

        return WWW::LogicBoxes::Customer->construct_from_response( $response );
    }
    catch {
        if( $_ =~ m/^Invalid customer-id/ ) {
            return;
        }

        croak $_;
    };
}

sub get_customer_by_username {
    my $self     = shift;
    my ( $username ) = pos_validated_list( \@_, { isa => EmailAddress } );

    return try {
        my $response = $self->submit({
            method => 'customers__details',
            params => {
                'username' => $username,
            }
        });

        return WWW::LogicBoxes::Customer->construct_from_response( $response );
    }
    catch {
        if( $_ =~ m/Customer [^\s]* not found/ ) {
            return;
        }

        croak $_;
    };
}

1;

__END__
=pod

=head1 NAME

WWW::LogicBoxes::Role::Command::Customer - Customer Related Operations

=head1 SYNPOSIS

    use WWW::LogicBoxes;
    use WWW::LogicBoxes::Customer;

    my $logic_boxes = WWW::LogicBoxes->new( ... );

    # Creation
    my $customer = WWW::LogicBoxes->new( ... );
    $logic_boxes->create_customer(
        customer => $customer,
        password => 'Top Secret!',
    );

    # Retrieval
    my $retrieved_customer = $logic_boxes->get_customer_by_id( $customer->id );
    my $retrieved_customer = $logic_boxes->get_customer_by_username( $customer->username ); # An email address

=head1 REQUIRES

submit

=head1 DESCRIPTION

Implements customer related operations with the L<LogicBoxes's|http://www.logicboxes.com> API.

=head1 METHODS

=head2 create_customer

    use WWW::LogicBoxes;
    use WWW::LogicBoxes::Customer;

    my $logic_boxes = WWW::LogicBoxes->new( ... );

    my $customer = WWW::LogicBoxes->new( ... );
    $logic_boxes->create_customer(
        customer => $customer,
        password => 'Top Secret!',
    );

    print 'New customer id: ' . $customer->id . "\n";

Given a L<WWW::LogicBoxes::Customer> or a HashRef that can coerced into a L<WWW::LogicBoxes::Customer> and a password, creates the specified customer.

=head2 get_customer_by_id

    use WWW::LogicBoxes;
    use WWW::LogicBoxes::Customer;

    my $logic_boxes = WWW::LogicBoxes->new( ... );

    my $retrieved_customer = $logic_boxes->get_customer_by_id( 42 );

Given an Integer ID, will return an instace of L<WWW::LogicBoxes::Customer>.  Returns undef if there is no matching L<WWW::LogicBoxes::Customer> with the specified id.

=head2 get_customer_by_username

    use WWW::LogicBoxes;
    use WWW::LogicBoxes::Customer;

    my $logic_boxes = WWW::LogicBoxes->new( ... );
    my $retrieved_customer = $logic_boxes->get_customer_by_username(
        'domainbuyer@test-domain.com'
    );

Given an Email Address of a customer, will return an instance of L<WWW::LogicBoxes::Customer>.  Returns undef if there is no matching L<WWW::LogicBoxes::Customer> with the specified email address.

=cut
