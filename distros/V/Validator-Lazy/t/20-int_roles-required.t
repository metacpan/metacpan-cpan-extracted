#!perl -T

use Modern::Perl;
use Test::Spec;

plan tests => 14;

use Validator::Lazy;

describe 'Internal roles' => sub {

    it 'Required' => sub {
        my $v = Validator::Lazy->new();

        ok( ! $v->check( Required => undef ) );
        is_deeply( $v->errors, [ { code => 'REQUIRED_ERROR', field => 'Required', data => {} } ] );

        ok( ! $v->check( Required => '' ) );
        is_deeply( $v->errors, [ { code => 'REQUIRED_ERROR', field => 'Required', data => {} } ] );

        ok( ! $v->check( Required => '  ' ) );
        is_deeply( $v->errors, [ { code => 'REQUIRED_ERROR', field => 'Required', data => {} } ] );

        ok( $v->check( Required => 0 ) );
        is_deeply( $v->errors, [ ] );

        ok( $v->check( Required => '0.0' ) );
        is_deeply( $v->errors, [ ] );

        ok( $v->check( Required => 123 ) );
        is_deeply( $v->errors, [ ] );

        ok( $v->check( Required => 'something' ) );
        is_deeply( $v->errors, [ ] );
    };
};

runtests unless caller;
