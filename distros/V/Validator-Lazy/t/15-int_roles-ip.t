#!perl -T

use Modern::Perl;
use Test::Spec;

plan tests => 24;

use Validator::Lazy;

describe 'Internal roles' => sub {

    it 'IP default' => sub {

        my $v = Validator::Lazy->new( );
        ok( $v->check( IP => '' ) );
        is_deeply( $v->errors, [ ] );

        ok( $v->check( IP => '127.0.0.1' ) );
        is_deeply( $v->errors, [ ] );

        ok( $v->check( IP => '8.8.8.8' ) );
        is_deeply( $v->errors, [ ] );

        ok( ! $v->check( IP => '888.8.8.8' ) );
        is_deeply( $v->errors, [ { code => 'IP_ERROR', field => 'IP', data => {} } ] );

        ok( ! $v->check( IP => '127.0.0.1/24' ) );
        is_deeply( $v->errors, [ { code => 'IP_ERROR', field => 'IP', data => {} } ] );

        ok( $v->check( IP => '192.1.1.0/24' ) );
        is_deeply( $v->errors, [ ] );
    };


    # ver => [ v4, v6 ], type => [ Public, Private, Reserved ]
    it 'IP with params' => sub {
        my $v = Validator::Lazy->new( { ip => { IP => { ver => 4, type => [ 'Public' ] } } } );

        ok( $v->check( ip => '' ) );
        is_deeply( $v->errors, [ ] );

        ok( !$v->check( ip => '127.0.0.1' ) );
        is_deeply( $v->errors, [ { code => 'IP_PUBLIC_TYPE_REQUIRED', field => 'ip', data => {} } ] );

        ok( $v->check( ip => '8.8.8.8' ) );
        is_deeply( $v->errors, [ ] );

        ok( !$v->check( ip => '::ffff:192.0.2.1' ) );
        is_deeply( $v->errors, [ { code => 'IP_V4_REQUIRED', field => 'ip', data => {} } ] );

    };

    it 'IP with params mask' => sub {
        my $v = Validator::Lazy->new( { ip => { IP => { mask => 24 } } } );

        ok( $v->check( ip => '192.1.1.0/24' ) );
        is_deeply( $v->errors, [ ] );

        ok( ! $v->check( ip => '8.8.8.8' ) );
        is_deeply( $v->errors, [ { code => 'MASK_ERROR', field => 'ip', data => { required => 24 } } ] );
    }
};

runtests unless caller;
