use strict;
use warnings;
use v5.10;
use lib '../lib';

use Test::More;

use Validator::LIVR;

Validator::LIVR->register_aliased_default_rule({
    name  => 'strong_password1',
    rules => { min_length => 8 },
    error => 'WEAK_PASSWORD1'
});

subtest 'Validate data with registered aliases' => sub {
    my $validator = Validator::LIVR->new({
        password1 => 'strong_password1',
        password2 => 'strong_password2'
    });

    $validator->register_aliased_rule({
        name  => 'strong_password2',
        rules => { min_length => 8 },
        error => 'WEAK_PASSWORD2'
    });

    ok( !$validator->validate({
        password1 => 'mypass',
        password2 => 'mypass'
    }), 'should return false due to validation errors' );

    is_deeply($validator->get_errors(), {
        password1 => 'WEAK_PASSWORD1',
        password2 => 'WEAK_PASSWORD2'
    }, 'Should contain error codes' );
};

done_testing();
