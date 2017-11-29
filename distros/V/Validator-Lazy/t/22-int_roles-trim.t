#!perl -T

use utf8;
use Modern::Perl;
use Test::Spec;

plan tests => 10;

use Validator::Lazy;

describe 'Internal roles' => sub {

    it 'left' => sub {
        my $v = Validator::Lazy->new( { tr => { Trim => 'left' } } );

        my( $ok, $data ) = $v->check( tr => '  	 something   to  fix  ' );

        is_deeply( $v->errors, [ ] );
        is_deeply( $data, { tr => 'something   to  fix  ' } );
    };

    it 'right' => sub {
        my $v = Validator::Lazy->new( { tr => { Trim => [ 'left', 'right' ] } } );

        my( $ok, $data ) = $v->check( tr => '  	 something   to  fix  ' );

        is_deeply( $v->errors, [ ] );
        is_deeply( $data, { tr => 'something   to  fix' } );
    };

    it 'right' => sub {
        my $v = Validator::Lazy->new( { tr => { Trim => 'right' } } );

        my( $ok, $data ) = $v->check( tr => '  	 something   to  fix  ' );

        is_deeply( $v->errors, [ ] );
        is_deeply( $data, { tr => '  	 something   to  fix' } );
     };

    it 'inner' => sub {
        my $v = Validator::Lazy->new( { tr => { Trim => 'inner' } } );

        my( $ok, $data ) = $v->check( tr => '  	 something   to  fix  ' );

        is_deeply( $v->errors, [ ] );
        is_deeply( $data, { tr => '  	 something to fix  ' } );
     };

    it 'all' => sub {
        my $v = Validator::Lazy->new( { tr => { Trim => 'all' } } );

        my( $ok, $data ) = $v->check( tr => '  	 something   to  fix  ' );

        is_deeply( $v->errors, [ ] );
        is_deeply( $data, { tr => 'something to fix' } );
     };

};

runtests unless caller;
