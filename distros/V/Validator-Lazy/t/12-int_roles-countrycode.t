#!perl -T

use Modern::Perl;
use Test::Spec;

plan tests => 10;

use Validator::Lazy;

describe 'Internal roles' => sub {

    it 'undef is ok' => sub {
        my $v = Validator::Lazy->new( { cc => { CountryCode => 'UA' } } );

        ok( $v->check( cc => undef ) );
        is_deeply( $v->errors, [ ] );
    };

    it 'empty is ok' => sub {
        my $v = Validator::Lazy->new( { cc => { CountryCode => 'UA' } } );

        ok( $v->check( cc => '' ) );
        is_deeply( $v->errors, [ ] );
    };

    it 'err is NOT ok' => sub {
        my $v = Validator::Lazy->new( { cc => { CountryCode => 'UA' } } );

        ok( ! $v->check( cc => 'DE' ) );
        is_deeply( $v->errors, [ { code => 'COUNTRYCODE_ERROR', field => 'cc', data => { required => [ 'UA' ] } } ] );
    };

    it 'err is NOT ok' => sub {
        my $v = Validator::Lazy->new( { cc => { CountryCode => [ 'UA', 'BR', 'US' ] } } );

        ok( ! $v->check( cc => 'DE' ) );
        is_deeply( $v->errors, [ { code => 'COUNTRYCODE_ERROR', field => 'cc', data => { required => [ 'UA', 'BR', 'US' ] } } ] );

        ok( $v->check( cc => 'BR' ) );
        is_deeply( $v->errors, [ ] );
    };
};

runtests unless caller;
