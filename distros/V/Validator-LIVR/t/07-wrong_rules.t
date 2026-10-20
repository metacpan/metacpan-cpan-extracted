use strict;
use warnings;
use v5.10;
use lib '../lib';

use Test::More;
use Test::Exception;

use Validator::LIVR;

subtest 'Rule with several names' => sub {
    my $validator = Validator::LIVR->new({
        field => [ 'required', { like => '^[A-Za-z]+$', max_length => 20 } ],
    });

    throws_ok { $validator->prepare() } qr/^Rule \[like, max_length\] should have one name$/,
        'Should not use one of the names';

    throws_ok { $validator->validate({ field => 'invalid_data' }) } qr/^Rule \[like, max_length\] should have one name$/,
        'Should not validate';
};

subtest 'Rule with several names in nested rules' => sub {
    throws_ok {
        Validator::LIVR->new({
            address => { nested_object => { zip => { min_length => 5, max_length => 10 } } },
        })->prepare();
    } qr/^Rule \[max_length, min_length\] should have one name$/, 'Should check nested_object rules';

    throws_ok {
        Validator::LIVR->new({ ids => { list_of => [ { min_number => 1, max_number => 10 } ] } })->prepare();
    } qr/^Rule \[max_number, min_number\] should have one name$/, 'Should check list_of rules';
};

subtest 'Rule without a name' => sub {
    throws_ok { Validator::LIVR->new({ field => {} })->prepare() } qr/^Rule \[\] should have one name$/,
        'Should not accept an empty hash';
};

subtest 'Unknown rule' => sub {
    throws_ok { Validator::LIVR->new({ field => 'no_such_rule' })->prepare() } qr/^Rule \[no_such_rule\] not registered$/,
        'Should not accept an unknown rule';
};

subtest 'Validation after a wrong rule' => sub {
    my $validator = Validator::LIVR->new({
        name     => 'required',
        email    => [ 'required', 'email' ],
        password => [ 'required', 'strong_pasword' ],
        phone    => 'required',
    });

    for my $call ( 1 .. 3 ) {
        throws_ok { $validator->validate({ password => '' }) } qr/^Rule \[strong_pasword\] not registered$/,
            "Should die on call $call too";
    }
};

done_testing();
