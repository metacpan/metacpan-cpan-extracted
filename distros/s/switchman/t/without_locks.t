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
        $o -> set_true( 'exists' );

        return $o;
    },
);

has lock_watch => (
    is => 'ro',
    lazy => 1,
    builder => sub { {}; },
);

sub get_lock {

    Test::More::fail();
    return undef;
}

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

use Test::More tests => 1;

my $switchman = TestApp -> new( {
    command => [ 'echo', '-n' ],
    lockname => 'dummy',
    prefix => '/dummy',
    zkhosts => 'localhost:2181',
    do_get_lock => 0,
    leases => {},
} );

$switchman -> run();

exit 0;

__END__
