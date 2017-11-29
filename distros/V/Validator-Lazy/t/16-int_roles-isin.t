#!perl -T

use Modern::Perl;
use Test::Spec;

plan tests => 6;

use Validator::Lazy;

describe 'Internal roles' => sub {

    it 'undef is ok' => sub {
        my $v = Validator::Lazy->new( { ii => { IsIn => [ 5,6,7 ] } } );

        ok( $v->check( ii => undef ) );
        is_deeply( $v->errors, [ ] );
    };

    it 'empty is NOT ok' => sub {
        my $v = Validator::Lazy->new( { ii => { IsIn => [ 5,6,7 ] } } );

        ok( $v->check( ii => '5' ) );
        is_deeply( $v->errors, [ ] );
    };

    it 'empty is NOT ok' => sub {
        my $v = Validator::Lazy->new( { ii => { IsIn => [ 5,6,7 ] } } );

        ok( ! $v->check( ii => '10' ) );
        is_deeply( $v->errors, [ { code => 'ISIN_ERROR', field => 'ii', data => { required => [ 5,6,7 ] } } ] );
    };
};

runtests unless caller;
