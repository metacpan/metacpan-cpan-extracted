use strict;
use warnings;

BEGIN {

    *CORE::GLOBAL::exit = sub {

        my ( $code ) = @_;

        if( caller() eq 'App::Switchman' ) {

            Test::More::is( $code, 0, 'exit(0)' );

        } else {

            Test::More::fail();
        }

        CORE::exit( $code );
    };
};

package TestApp;

use Moo;
use Test::MockObject ();

extends 'App::Switchman';

has zkh => (
    is => 'rw',
    lazy => 1,
    builder => sub {

        my $o = Test::MockObject -> new();

        $o -> set_isa( 'Net::ZooKeeper' );
        $o -> set_false( 'get_error' );

        my $is_lock_taken = 0;
        my @exists = (
            sub {
                Test::More::is( scalar( @_ ), 2, 'exists(): 1: got exactly two parameters' );
                Test::More::is( $_[ 1 ], '/dummy', 'exists(): 1: looking for prefix' );

                return 1;
            },
            sub {
                Test::More::is( scalar( @_ ), 4, 'exists(): 2: got exactly four parameters' );
                Test::More::is( $_[ 1 ], '/dummy/locks/dummy', 'exists(): 2: looking for lock' );

                return 0;
            },
            sub {
                Test::More::is( scalar( @_ ), 4, 'exists(): 3: got exactly four parameters' );
                Test::More::is( $_[ 1 ], '/dummy/locks/dummy', 'exists(): 3: verifying lock' );
                Test::More::ok( $is_lock_taken, 'exists(): 3: lock has been taken' );

                return 1;
            },
            sub {
                Test::More::fail();

                return 1;
            },
        );

        $o -> mock( exists => sub {
            shift( @exists ) -> ( @_ );
        } );

        $o -> mock( create => sub {

            if( $is_lock_taken ) {

                Test::More::fail();

            } else {

                Test::More::is( scalar( @_ ), 7, 'create(): got exactly seven parameters' );
                Test::More::is( $_[ 1 ], '/dummy/locks/dummy', 'create(): taking lock' );
                $is_lock_taken = 1;
            }

            return $_[ 1 ];
        } );

        return $o;
    },
);

has lock_watch => (
    is => 'ro',
    lazy => 1,
    builder => sub { {}; },
);

sub _build_log {

    my $o = Test::MockObject -> new();

    $o -> set_isa( 'Log::Dispatch' );
    $o -> mock( info => sub {} );
    $o -> mock( debug => sub {} );

    return $o;
}

sub prepare_zknodes { }

sub load_prefix_data {

    my ( $self ) = @_;

    $self -> prefix_data( { resources => [], groups => [] } );
}

no Moo;

package main;

use Test::More tests => 10;

my $switchman = TestApp -> new( {
    command => [ 'echo', '-n' ],
    lockname => 'dummy',
    prefix => '/dummy',
    zkhosts => 'localhost:2181',
    do_get_lock => 1,
    leases => {},
} );

$switchman -> run();

exit 0;

__END__
