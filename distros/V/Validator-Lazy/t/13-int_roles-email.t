#!perl -T

use Modern::Perl;
use Test::Spec;

plan tests => 8;

use Validator::Lazy;

describe 'Internal roles' => sub {

    # All params are the same as in https://metacpan.org/pod/Email::Valid
    # Defaults are:
    # -tldcheck     => 1,
    # -fudge        => 1,
    # -fqdn         => 1,
    # -allow_ip     => 0,
    # -mxcheck      => 0,
    # -local_rules  => 0,

    it 'Email default' => sub {

        my $v = Validator::Lazy->new( );
        ok( $v->check( Email => '' ) );
        is_deeply( $v->errors, [ ] );

        ok( ! $v->check( Email => 'name@badname.badtld' ) );

        is_deeply( $v->errors, [ { code => 'EMAIL_ERROR', field => 'Email', data => { error_code => 'tldcheck' } } ] );

        ok( $v->check( Email => 'name@godaddy.com' ) );
        is_deeply( $v->errors, [ ] );
    };

    it 'Email with params' => sub {
        my $v = Validator::Lazy->new( { em => { Email => { -tldcheck => 0 } } } );

        ok( $v->check( em => 'name@badname.badtld' ) );
        is_deeply( $v->errors, [ ] );
    };
};

runtests unless caller;
