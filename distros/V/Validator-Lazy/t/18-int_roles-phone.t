#!perl -T

use Modern::Perl;
use Test::Spec;

plan tests => 18;

use Validator::Lazy;

describe 'Internal roles' => sub {

    it 'Phone' => sub {
        my $v = Validator::Lazy->new();

        ok( $v->check( Phone => '' ), 'not required' );
        is_deeply( $v->errors, [ ], 'wrong format' );

        $v->check( Phone => '  asdjfakdgfashd  ' );
        is_deeply( $v->errors, [ { code => 'PHONE_BAD_FORMAT', field => 'Phone', data => {} } ], 'wrong number' );

        $v->check( Phone => '  +3805977755533  ' );
        is_deeply( $v->errors, [ { code => 'PHONE_BAD_NUMBER', field => 'Phone', data => {} } ], 'wrong number' );

        my( $res, $data ) = $v->check( Phone => '+380502087712' );
        ok( $res );
        is_deeply( $v->errors, [ ], 'phone ok' );
        is_deeply( $data, { Phone => '+380502087712' } );

        # List params
        $v = Validator::Lazy->new( { phone => { Phone => [ 'mobile' ] } } );
        $v->check( phone => '+380501230987' );
        is_deeply( $v->errors, [ ], 'phone ok' );

        $v = Validator::Lazy->new( { phone => { Phone => [ 'not_mobile' ] } } );
        $v->check( phone => '+380501230987' );
        is_deeply( $v->errors, [ { code => 'PHONE_IS_MOBILE', field => 'phone', data => {} } ], 'wrong number' );


        $v = Validator::Lazy->new( { phone => { Phone => [ 'US' ] } } );
        $v->check( phone => '+380501230987' );
        is_deeply( $v->errors, [ { code => 'PHONE_WRONG_COUNTRY', field => 'phone', data => { 'current' => 'UA', 'required' => ['US'] } } ], 'wrong number' );

        $v = Validator::Lazy->new( { phone => { Phone => [ 'UA' ] } } );
        $v->check( phone => '+380501230987' );
        is_deeply( $v->errors, [ ], 'phone ok' );

        # Hash params
        $v = Validator::Lazy->new( { phone => { Phone => { mobile => 1 } } } );
        $v->check( phone => '+380501230987' );
        is_deeply( $v->errors, [ ], 'phone ok' );

        $v = Validator::Lazy->new( { phone => { Phone => { not_mobile => 1 } } } );
        $v->check( phone => '+380501230987' );
        is_deeply( $v->errors, [ { code => 'PHONE_IS_MOBILE', field => 'phone', data => {} } ], 'wrong number' );

        $v = Validator::Lazy->new( { phone => { Phone => { country => 'US' } } } );
        $v->check( phone => '+380501230987' );
        is_deeply( $v->errors, [ { code => 'PHONE_WRONG_COUNTRY', field => 'phone', data => { 'current' => 'UA', 'required' => ['US'] } } ], 'wrong number' );

        $v = Validator::Lazy->new( { phone => { Phone => { country => ['US'] } } } );
        $v->check( phone => '+380501230987' );
        is_deeply( $v->errors, [ { code => 'PHONE_WRONG_COUNTRY', field => 'phone', data => { 'current' => 'UA', 'required' => ['US'] } } ], 'wrong number' );

        $v = Validator::Lazy->new( { phone => { Phone => { country => 'UA' } } } );
        $v->check( phone => '+380501230987' );
        is_deeply( $v->errors, [ ], 'phone ok' );

        $v = Validator::Lazy->new( { phone => { Phone => { country => ['UA'] } } } );
        $v->check( phone => '+380501230987' );
        is_deeply( $v->errors, [ ], 'phone ok' );

        # Just a mix
        $v = Validator::Lazy->new( { phone => { Phone => { country => 'UA', not_mobile => 1 } } } );
        $v->check( phone => '+380441230987' );
        is_deeply( $v->errors, [ ], 'phone ok' );

    };
};

runtests unless caller;
