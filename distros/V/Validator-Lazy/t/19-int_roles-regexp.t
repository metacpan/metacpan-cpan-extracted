#!perl -T

use Modern::Perl;
use Test::Spec;

plan tests => 20;

use Validator::Lazy;

describe 'Internal roles' => sub {

    describe 'Required' => sub {

        it 'no modifiers' => sub {
            my $v = Validator::Lazy->new( { regexp => { RegExp => '/[A-Z]/' } } );

            ok( $v->check( regexp => undef ) );
            is_deeply( $v->errors, [ ] );

            ok( $v->check( regexp => '' ) );
            is_deeply( $v->errors, [ ] );

            ok( ! $v->check( regexp => 'abcdef' ) );
            is_deeply( $v->errors, [ { code => 'REGEXP_ERROR', field => 'regexp', data => { exp => '/[A-Z]/' } } ] );

            ok( $v->check( regexp => 'FGH' ) );
            is_deeply( $v->errors, [ ] );
        };

        it 'm = i' => sub {
            my $v = Validator::Lazy->new( { regexp => { RegExp => '/[A-Z]/i' } } );

            ok( $v->check( regexp => 'abcdef' ) );
            is_deeply( $v->errors, [ ] );
        };

        it 'reglist' => sub {
            my $v = Validator::Lazy->new( { regexp => { RegExp => [ '/[A-Z]/', '/[a-z]/' ] } } );

            ok( ! $v->check( regexp => '12345' ) );
            is_deeply( $v->errors, [
                { code => 'REGEXP_ERROR', field => 'regexp', data => { exp => '/[A-Z]/' } },
                { code => 'REGEXP_ERROR', field => 'regexp', data => { exp => '/[a-z]/' } },
            ] );

            ok( ! $v->check( regexp => 'abcdef' ) );
            is_deeply( $v->errors, [ { code => 'REGEXP_ERROR', field => 'regexp', data => { exp => '/[A-Z]/' } } ] );

            ok( ! $v->check( regexp => 'ABCDEF' ) );
            is_deeply( $v->errors, [ { code => 'REGEXP_ERROR', field => 'regexp', data => { exp => '/[a-z]/' } } ] );

            ok( $v->check( regexp => 'ABCdef' ) );
            is_deeply( $v->errors, [ ] );
        };

        it 'reglist' => sub {
            my $v = Validator::Lazy->new( { regexp => { RegExp => '/[A-Z] [0-9]/ix' } } );

            ok( $v->check( regexp => 'ABCdef12345' ) );
            is_deeply( $v->errors, [ ] );
        };
    };
};

runtests unless caller;
