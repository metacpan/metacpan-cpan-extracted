package Test::WWW::eNom::Contact;

use strict;
use warnings;

use Test::More;
use Test::Exception;
use String::Random qw( random_string );
use MooseX::Params::Validate;

use WWW::eNom::Types qw( EmailAddress PhoneNumber Str );
use WWW::eNom::Contact;

use Readonly;
Readonly our $DEFAULT_CONTACT => WWW::eNom::Contact->new(
    first_name   => 'Ada',
    last_name    => 'Byron',
    address1     => 'University of London',
    city         => 'London',
    country      => 'GB',
    zipcode      => 'WC1E 7HU',
    email        => 'ada-' . random_string('ccnnccnnccnnccnnccnnccnn') . '@testing.com',
    phone_number => '18005551212',
);

use Exporter 'import';
our @EXPORT_OK = qw(
    create_contact
    $DEFAULT_CONTACT
);

sub create_contact {
    my ( %args ) = validated_hash(
        \@_,
        first_name        => { isa => Str, optional => 1 },
        last_name         => { isa => Str, optional => 1 },
        organization_name => { isa => Str, optional => 1 },
        job_title         => { isa => Str, optional => 1 },
        address1          => { isa => Str, optional => 1 },
        address2          => { isa => Str, optional => 1 },
        city              => { isa => Str, optional => 1 },
        state             => { isa => Str, optional => 1 },
        country           => { isa => Str, optional => 1 },
        zipcode           => { isa => Str, optional => 1 },
        email             => { isa => EmailAddress, optional => 1 },
        phone_number      => { isa => PhoneNumber,  optional => 1, coerce => 1 },
        fax_number        => { isa => PhoneNumber,  optional => 1, coerce => 1 },
    );

    if( $args{organization_name} ) {
        $args{job_title}  //= 'Countess of Lovelace';
        $args{fax_number} //= '18005551212';
    }

    $args{first_name}   //= 'Ada';
    $args{last_name}    //= 'Byron';
    $args{address1}     //= 'University of London';
    $args{city}         //= 'London';
    $args{country}      //= 'GB';
    $args{zipcode}      //= 'WC1E 7HU';
    $args{email}        //= 'ada-' . random_string('ccnnccnnccnnccnnccnnccnn') . '@testing.com';
    $args{phone_number} //= '18005551212';

    my $contact;
    subtest 'Create Contact' => sub {
        lives_ok {
            $contact = WWW::eNom::Contact->new( %args );
        } 'Lives through contact creation';

        note( 'Contact Email: ' . $contact->email );
    };

    return $contact;
}

1;
