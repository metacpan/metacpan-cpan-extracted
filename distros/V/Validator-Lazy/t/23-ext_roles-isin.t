#!perl -T

use Modern::Perl;
use Test::Spec;

plan tests => 11;

use Validator::Lazy;

describe 'External roles' => sub {

    it 'undef is ok' => sub {
        my $v = Validator::Lazy->new( { ii => { 'Validator::Lazy::Role::Check::IsIn' => [ 5,6,7 ] } } );

        ok( $v->check( ii => undef ) );
        is_deeply( $v->errors, [ ] );
    };

    it 'empty is NOT ok' => sub {
        my $v = Validator::Lazy->new( { ii => { 'Validator::Lazy::Role::Check::IsIn' => [ 5,6,7 ] } } );

        ok( $v->check( ii => '5' ) );
        is_deeply( $v->errors, [ ] );
    };

    it 'empty is NOT ok' => sub {
        my $v = Validator::Lazy->new( { ii => { 'Validator::Lazy::Role::Check::IsIn' => [ 5,6,7 ] } } );

        ok( ! $v->check( ii => '10' ) );
        is_deeply( $v->errors, [ { code => 'ISIN_ERROR', field => 'ii', data => { required => [ 5,6,7 ] } } ] );
    };

    it 'empty is NOT ok' => sub {

        my $config = q~
            xx: 'Validator::Lazy::TestRole::ExtRoleExample'

            zz:
                - Required
                - xx
        ~;

        my $v = Validator::Lazy->new( $config );

        ok( ! $v->check( zz => '' ) );
        is_deeply( $v->errors, [ { code => 'REQUIRED_ERROR', field => 'zz', data => {} } ] );

        ok( ! $v->check( zz => '0' ), 'Ext role error' );
        is_deeply( $v->errors, [ { code => uc( 'Validator_Lazy_TestRole_ExtRoleExample_Error' ), field => 'zz', data => {} } ] );

        is( $v->data->{zz}, 111, 'data has been corrected' );
    };
};

runtests unless caller;
