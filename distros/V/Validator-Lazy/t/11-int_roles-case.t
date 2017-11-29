#!perl -T

use utf8;
use Modern::Perl;
use Test::Spec;

plan tests => 10;

use Validator::Lazy;

describe 'Internal roles' => sub {

    describe 'Required' => sub {

        it 'upper' => sub {
            my $v = Validator::Lazy->new( { cs => { Case => 'upper' } } );

            my( $ok, $data ) = $v->check( cs => 'someTHing To fIX,here WE have' );
            is_deeply( $v->errors, [ ] );
            is_deeply( $data, { cs => 'SOMETHING TO FIX,HERE WE HAVE' } );
        };

        it 'lower' => sub {
            my $v = Validator::Lazy->new( { cs => { Case => 'lower' } } );

            my( $ok, $data ) = $v->check( cs => 'someTHing To fIX,here WE have' );
            is_deeply( $v->errors, [ ] );
            is_deeply( $data, { cs => 'something to fix,here we have' } );
        };

        it 'first_upper' => sub {
            my $v = Validator::Lazy->new( { cs => { Case => 'first_upper' } } );

            my( $ok, $data ) = $v->check( cs => 'someTHing To fIX,here WE have' );
            is_deeply( $v->errors, [ ] );
            is_deeply( $data, { cs => 'Something to fix,here we have' } );
        };

        it 'all_first_upper' => sub {
            my $v = Validator::Lazy->new( { cs => { Case => 'all_first_upper' } } );

            my( $ok, $data ) = $v->check( cs => 'someTHing To fIX,here WE have' );
            is_deeply( $v->errors, [ ] );
            is_deeply( $data, { cs => 'Something To Fix,Here We Have' } );
        };

        it 'all_first_upper' => sub {
            my $v = Validator::Lazy->new( { cs => { Case => 'all_first_upper' } } );

            my( $ok, $data ) = $v->check( cs => 'Что-то неПОнятное,-что надо ИСправить' );
            is_deeply( $v->errors, [ ] );
            is_deeply( $data, { cs => 'Что-То Непонятное,-Что Надо Исправить' } );
        };
    };
};

runtests unless caller;
