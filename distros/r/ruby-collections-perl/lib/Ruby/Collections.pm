package Ruby::Collections;
use Exporter 'import';
@EXPORT = qw(ra rh p p_obj p_array p_hash);
our $VERSION = '0.12';
use strict;
use v5.10;
use Scalar::Util qw(reftype);
use FindBin;
use lib "$FindBin::Bin/../../lib";
require Ruby::Collections::Hash;
require Ruby::Collections::Array;

=item ra()
  Create a Ruby::Collections::Array with optional arguments or any array ref.
  If array ref is also a Ruby::Collections::Array, it will be nested in instead of wrapped up.
  
  Examples:
  ra                  -> []
  ra( 1, 2, 3 )       -> [ 1, 2, 3 ]
  ra( [ 1, 2, 3 ] )   -> [ 1, 2, 3 ]
  ra( ra( 1, 2, 3 ) ) -> [ [ 1, 2, 3 ] ]
=cut

sub ra {
	my $new_ary = tie my @new_ary, 'Ruby::Collections::Array';
	if (   @_ == 1
		&& reftype( $_[0] ) eq 'ARRAY'
		&& ref( $_[0] ) ne 'Ruby::Collections::Array' )
	{
		@new_ary = @{ $_[0] };
	}
	else {
		@new_ary = @_;
	}

	return $new_ary;
}

=item rh()
  Create a Ruby::Collections::Hash with optional arguments or any hash ref.
  
  Examples:
  rh                 -> {}
  rh( { 'a' => 1 } ) -> { 'a' => 1 }
  rh( 'a' => 1 )     -> { 'a' => 1 }
  rh( 'a', 1 )       -> { 'a' => 1 }
=cut

sub rh {
	my $new_hash = tie my %new_hash, 'Ruby::Collections::Hash';
	%new_hash = ();

	if ( @_ == 0 ) {
		return $new_hash;
	}
	elsif ( @_ == 1 ) {
		if ( reftype( $_[0] ) eq 'HASH' ) {
			%new_hash = %{ $_[0] };
		}
		else {
			die 'Input is not a HASH.';
		}
	}
	else {
		if ( @_ % 2 == 0 ) {
			for ( my $i = 0 ; $i < @_ ; $i += 2 ) {
				$new_hash->{ $_[$i] } = $_[ $i + 1 ];
			}
		}
		else {
			die 'Number of keys and values is not even.';
		}
	}

	return $new_hash;
}

=item p()
  Print the data structure of any object.
  If the object is simply a scalar, it will be printed out directly.
  Undefined object will be printed as 'undef' instead of ''.
=cut

sub p {
	for my $item (@_) {
		if ( reftype($item) eq 'ARRAY' ) {
			say p_array($item);
		}
		elsif ( reftype($item) eq 'HASH' ) {
			say p_hash($item);
		}
		else {
			say defined $item ? "$item" : 'undef';
		}
	}
}

=item p_obj()
  Same as p(). Instead of printing the result, it simply returns a string.
=cut

sub p_obj {
	my $str_ary = ra;
	for my $item (@_) {
		if ( reftype($item) eq 'ARRAY' ) {
			$str_ary->push( p_array($item) );
		}
		elsif ( reftype($item) eq 'HASH' ) {
			$str_ary->push( p_hash($item) );
		}
		else {
			$str_ary->push( ( defined $item ) ? "$item" : 'undef' );
		}
	}
	return $str_ary->join("\n");
}

=item p_array()
  Retuen the stringfied data structure of any ARRAY.
  Undefined object will be printed as 'undef' instead of ''.
=cut

sub p_array {
	my $ary     = shift @_;
	my @str_ary = ();

	for my $item ( @{$ary} ) {
		if ( reftype($item) eq 'ARRAY' ) {
			push( @str_ary, p_array($item) );
		}
		elsif ( reftype($item) eq 'HASH' ) {
			push( @str_ary, p_hash($item) );
		}
		else {
			push( @str_ary, defined $item ? "$item" : 'undef' );
		}
	}

	return '[' . join( ', ', @str_ary ) . ']';
}

=item p_hash()
  Print the stringfied data structure of any HASH.
  Undefined object will be printed as 'undef' instead of ''.
=cut

sub p_hash {
	my $hash        = shift @_;
	my @str_ary     = ();
	my @key_str_ary = ();
	my @val_str_ary = ();

	while ( my ( $key, $val ) = each %$hash ) {
		if ( reftype($key) eq 'ARRAY' ) {
			push( @key_str_ary, p_array($key) );
		}
		elsif ( reftype($key) eq 'HASH' ) {
			push( @key_str_ary, p_hash($key) );
		}
		else {
			push( @key_str_ary, defined $key ? "$key" : 'undef' );
		}

		if ( reftype($val) eq 'ARRAY' ) {
			push( @val_str_ary, p_array($val) );
		}
		elsif ( reftype($val) eq 'HASH' ) {
			push( @val_str_ary, p_hash($val) );
		}
		else {
			push( @val_str_ary, defined $val ? "$val" : 'undef' );
		}
	}

	for ( my $i = 0 ; $i < scalar(@key_str_ary) ; $i++ ) {
		@str_ary[$i] = @key_str_ary[$i] . '=>' . @val_str_ary[$i];
	}

	return '{' . join( ', ', @str_ary ) . '}';
}

1;
__END__;
