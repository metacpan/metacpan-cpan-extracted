package main;

use 5.010;

use strict;
use warnings;

use Carp;
use Test::More 0.88;	# Because of done_testing();
use Test::Prereq::Meta;

test_norm( AmigaOS	=> 'foo/bar', 'foo/bar' );

test_norm( Cygwin	=> 'foo/bar', 'foo/bar' );

test_norm( OS2		=> 'foo\\bar', 'foo/bar' );

test_norm( Unix		=> 'foo/bar', 'foo/bar' );

{
    local $@ = undef;

    if (
	eval {
	    test_norm( VMS		=> '[.foo]bar', 'foo/bar' );
	    1;
	}
    ) {
	fail( 'VMS test succeeded unexpectedly' );
    } else {
	like( $@, qr<\ACan not normalize VMS paths\b>sm,
	    q<Normalizing '[.foo]bar' under VMS gives expected error> );
    }
}

test_norm( Win32	=> 'foo\\bar', 'foo/bar' );

done_testing;

sub test_norm {
    my ( $path_type, $norm, $want, $name ) = @_;
    $name //= "Normalizing '$norm' under $path_type gives '$want'";
    my $code = Test::Prereq::Meta->can( "__normalize_path_$path_type" )
	or confess( "Programming error - Invalid path type '$path_type'" );
    local $_ = $norm;
    $code->();
    @_ = ( $_, $want, $name );
    goto &is;
}

1;

# ex: set textwidth=72 :
