package Test::WWW::LogicBoxes::Customer;

use strict;
use warnings;

use Test::More;
use Test::Exception;
use String::Random qw( random_string );
use MooseX::Params::Validate;

use Test::WWW::LogicBoxes qw( create_api );

use WWW::LogicBoxes::Types qw( EmailAddress Password Str PhoneNumber );
use WWW::LogicBoxes::Customer;

use Exporter 'import';
our @EXPORT_OK = qw( create_customer );

sub create_customer {
    my ( %args ) = validated_hash(
        \@_,
        username     => { isa => EmailAddress, optional => 1 },
        password     => { isa => Password,     optional => 1 },
        name         => { isa => Str,          optional => 1 },
        company      => { isa => Str,          optional => 1 },
        address1     => { isa => Str,          optional => 1 },
        address2     => { isa => Str,          optional => 1 },
        address3     => { isa => Str,          optional => 1 },
        city         => { isa => Str,          optional => 1 },
        state        => { isa => Str,          optional => 1 },
        country      => { isa => Str,          optional => 1 },
        zipcode      => { isa => Str,          optional => 1 },
        phone_number        => { isa => PhoneNumber, optional => 1 },
        fax_number          => { isa => PhoneNumber, optional => 1 },
        mobile_phone_number => { isa => PhoneNumber, optional => 1 },
        alt_phone_number    => { isa => PhoneNumber, optional => 1 },
    );

    my $password = $args{password} //= random_string('ccnnccnnccnn');
    delete $args{password};

    $args{username} //= 'test-' . random_string('ccnnccnnccnnccnnccnnccnn') . '@testing.com';
    $args{name}     //= 'Alan Turning',
    $args{company}  //= 'Princeton University',
    $args{address1} //= '123 Turning Machine Way',
    $args{address2} //= 'Office P is equal to NP',
    $args{city}     //= 'New York',
    $args{state}    //= 'New York',
    $args{country}  //= 'US';
    $args{zipcode}  //= '10108',
    $args{phone_number}        //= '18005551212';
    $args{fax_number}          //= '18005551212';
    $args{mobile_phone_number} //= '18005551212';
    $args{alt_phone_number}    //= '18005551212';

    my $api = create_api( );

    my $customer;
    subtest 'Create Customer' => sub {
        lives_ok {
            $customer = WWW::LogicBoxes::Customer->new(\%args);
            $api->create_customer(
                customer => $customer,
                password => $password,
            );
        } 'Lives through customer creation';

        note('Customer ID: ' . $customer->id);
    };

    return $customer;
}

1;
