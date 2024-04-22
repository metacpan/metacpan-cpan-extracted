#! perl

package Text::Layout::Utils;

use v5.26;
use utf8;
use Carp;
use feature qw( signatures );
no warnings "experimental::signatures";

use Exporter 'import';
our @EXPORT;

# Split (pseudo) command line into key/value pairs.

sub parse_kv ( @lines ) {

    use Text::ParseWords qw(shellwords);
    my @words = shellwords(@lines);

    my $res = {};
    foreach ( @words ) {
	if ( /^(.*?)=(.+)/ ) {
	    $res->{$1} = $2;
	}
	elsif ( /^no[-_]?(.+)/ ) {
	    $res->{$1} = 0;
	}
	else {
	    $res->{$_}++;
	}
    }

    return $res;
}

push( @EXPORT, 'parse_kv' );

# Remove markup.
sub demarkup ( $t ) {
    return join( '', grep { ! /^\</ } splitmarkup($t) );
}
push( @EXPORT, 'demarkup' );

# Split into markup/nonmarkup segments.
sub splitmarkup ( $t ) {
    my @t = split( qr;(</?(?:[-\w]+|span\s.*?)>);, $t );
    return @t;
}
push( @EXPORT, 'splitmarkup' );

# For conditional filling of hashes.
sub maybe ( $key, $value, @rest ) {
    if (defined $key and defined $value) {
	return ( $key, $value, @rest );
    }
    else {
	( defined($key) || @rest ) ? @rest : ();
    }
}
push( @EXPORT, "maybe" );

# Min/Max.
sub min { $_[0] < $_[1] ? $_[0] : $_[1] }
sub max { $_[0] > $_[1] ? $_[0] : $_[1] }

push( @EXPORT, "min", "max" );

1;
