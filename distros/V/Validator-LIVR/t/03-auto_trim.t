use strict;
use warnings;
use v5.10;
use lib '../lib';

use Test::More;
use Test::Exception;

use Validator::LIVR;

my $validator = Validator::LIVR->new({
    code           => 'required',
    password       => ['required', { min_length => 3 }],
    address        => { nested_object  => {
        street   => { 'min_length' => 5 },
    } }
}, 'is_auto_trim');

subtest 'Validate data with automatic trim' => sub {
    lives_ok { $validator->prepare() } 'Should build all rules';

    ok( !$validator->validate({
        code => '  ',
        password => ' 12  ',
        address => {
            street   => '  hell '
        }
    }), 'should return false due to validation errors fot trimmed values' );

    is_deeply($validator->get_errors(), {
        code     =>'REQUIRED',
        password => 'TOO_SHORT',
        address  => {
            street   => 'TOO_SHORT',
        }
    }, 'Should contain error codes' );
};

subtest 'Validate data with automatic trim' => sub {
    lives_ok { $validator->prepare() } 'Should build all rules';

    ok( my $clean_data = $validator->validate({
        code => ' A ',
        password => ' 123  ',
        address => {
            street   => '  hello '
        }
    }), 'should return clean data' );

    is_deeply($clean_data, {
        code     =>'A',
        password => '123',
        address  => {
            street   => 'hello',
        }
    }, 'Should contain trimmed data' );
};


done_testing();