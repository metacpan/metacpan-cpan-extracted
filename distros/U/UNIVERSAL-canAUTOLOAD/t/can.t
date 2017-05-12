#!perl -w
use strict;
use Test::More tests => 14;

BEGIN { use_ok 'UNIVERSAL::canAUTOLOAD' }

my @called;
package Parent;
sub upper {
    push @called, [ upper => @_ ];
}

package Can;
use base 'Parent';
our $AUTOLOAD;
sub AUTOLOAD {
    push @called, { AUTOLOAD => $AUTOLOAD };
}

sub exists {
    push @called, "exists";
}

package main;

can_ok( Can => 'anything' );
is_deeply( \@called, [], "empty" );

my $fred = Can->can( 'fred' );
ok( $fred, "got fred" );
is( ref $fred, "CODE" );

my $barney = Can->can( 'barney' );
ok( $fred->(), "called fred" );

is_deeply( \@called, [ { AUTOLOAD => 'Can::fred' } ], "really called fred" );
@called = ();

my $exists = Can->can( 'exists' );
is( $exists, \&Can::exists, "got something that exists" );
ok( $exists->(), "called exists" );

is_deeply( \@called, [ "exists" ], "really called exists" );
@called = ();

my $upper = Can->can( 'upper' );
is( $upper, \&Parent::upper );
ok( $upper->( 'badger' ), "called upper" );

is_deeply( \@called, [ [ upper => 'badger' ] ], "called the right thing" );

is_deeply( [ Foo->can('bar') ], [ undef ], "compatible version of falsehood" );
