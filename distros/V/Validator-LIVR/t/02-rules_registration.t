use strict;
use warnings;
use v5.10;
use lib '../lib';

use Test::More;
use Test::Exception;

use Validator::LIVR;

Validator::LIVR->register_default_rules(
    'strong_password' => sub {
        return sub {
            my $value = shift;
            return if !defined($value) || $value eq '';

            return 'WEAK_PASSWORD' if length($value) < 6;
            return;
        }
    }
);

my $validator = Validator::LIVR->new({
    code           => 'alphanumeric',
    password       => 'strong_password',
    address        => { nested_object  => {
        street   => 'alphanumeric',
        password => 'strong_password'
    } }
});

$validator->register_rules( 'alphanumeric' => sub {
    return sub {
        my $value = shift;
        return if !defined($value) || $value eq '';

        return 'NOT_ALPHANUMERIC' if $value !~ /^[a-z0-9]+$/;
        return;
    }
});


subtest 'Check default rules existence' => sub {
    my $rules = Validator::LIVR->get_default_rules();
    ok( ref( $rules->{strong_password} ) eq 'CODE', 'Default rules should contain "strong_password" rule' );
    ok( ! exists $rules->{alphanumeric}, 'Default rules should not contain "alphanumeric" rule' );
};


subtest 'Check validator rules existence' => sub {
    my $rules = $validator->get_rules();
    ok( ref( $rules->{strong_password} ) eq 'CODE', 'Validator rules should contain "strong_password" rule' );
    ok( ref( $rules->{alphanumeric} ) eq 'CODE', 'Validator rules should contain "alphanumeric" rule' );
};


subtest 'Validate data with registered rules' => sub {
    lives_ok { $validator->prepare() } 'Should build all rules';

    ok( !$validator->validate({
        code => '!qwe',
        password => 123,
        address => {
            street   => 'Some Street!',
            password => 'qwer'
        }
    }), 'should return false due to validation errors' );

    is_deeply($validator->get_errors(), {
        code     =>'NOT_ALPHANUMERIC',
        password => 'WEAK_PASSWORD',
        address  => {
            street   => 'NOT_ALPHANUMERIC',
            password => 'WEAK_PASSWORD'
        }
    }, 'Should contain error codes' );
};


done_testing();