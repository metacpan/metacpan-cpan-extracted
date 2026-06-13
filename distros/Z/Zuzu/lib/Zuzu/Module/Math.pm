package Zuzu::Module::Math;

use utf8;

our $VERSION = '0.004000';

use List::Util qw(
	max
	min
	sum
);
use Math::BigInt;
use Math::Trig qw(
	acosec
	acosech
	acos
	acosh
	acotan
	acotanh
	asec
	asech
	asin
	asinh
	atan
	atanh
	cosec
	cosech
	cosh
	cotan
	cotanh
	pi
	sec
	sech
	sinh
	tan
	tanh
);

use Zuzu::Util::NativeHelpers qw(
	native_class
	native_functions
);

sub _num {
	my ( $value, $default ) = @_;

	return $default if not defined $value;
	return 0 + $value;
}

sub _parse_radix_string {
	my ( $value, $base, $name ) = @_;

	my $raw = defined $value ? "$value" : '';
	my $text = $raw;
	$text =~ s/^0[xX]// if $base == 16;

	my %pattern = (
		2 => qr/\A[01]+\z/,
		8 => qr/\A[0-7]+\z/,
		10 => qr/\A[0-9]+\z/,
		16 => qr/\A[0-9A-Fa-f]+\z/,
	);

	die "TypeException: $name expects a base-$base numeric string"
		if $text !~ $pattern{$base};

	if ( $base == 2 ) {
		return Math::BigInt->from_bin( '0b' . $text );
	}
	if ( $base == 8 ) {
		return Math::BigInt->from_oct( '0' . $text );
	}
	if ( $base == 10 ) {
		return Math::BigInt->new($text);
	}
	return Math::BigInt->from_hex( '0x' . $text );
}

sub _stringify_radix {
	my ( $num, $base ) = @_;

	my $out = substr( $num->as_bin(), 2 )
		if $base == 2;
	$out = substr( $num->as_oct(), 1 )
		if $base == 8;
	$out = $num->bstr()
		if $base == 10;
	$out = substr( $num->as_hex(), 2 )
		if $base == 16;

	return pack 'A*', $out;
}

sub IMPORT {
	my ( $class, $runtime ) = @_;

	my $math_class = native_class(
		name => 'Math',
	);

	my @trig_names = qw(
		sin cos tan
		cosec sec cotan
		asin acos atan atan2 acosec asec acotan
		sinh cosh tanh
		cosech sech cotanh
		asinh acosh atanh acosech asech acotanh
	);
	my %trig_impl = (
		sin => sub { CORE::sin( _num( $_[0], 0 ) ) },
		cos => sub { CORE::cos( _num( $_[0], 0 ) ) },
		tan => sub { tan( _num( $_[0], 0 ) ) },
		cosec => sub { cosec( _num( $_[0], 0 ) ) },
		sec => sub { sec( _num( $_[0], 0 ) ) },
		cotan => sub { cotan( _num( $_[0], 0 ) ) },
		asin => sub { asin( _num( $_[0], 0 ) ) },
		acos => sub { acos( _num( $_[0], 0 ) ) },
		atan => sub { atan( _num( $_[0], 0 ) ) },
		atan2 => sub {
			my ( $y, $x ) = @_;
			return CORE::atan2( _num( $y, 0 ), _num( $x, 1 ) );
		},
		acosec => sub { acosec( _num( $_[0], 0 ) ) },
		asec => sub { asec( _num( $_[0], 0 ) ) },
		acotan => sub { acotan( _num( $_[0], 0 ) ) },
		sinh => sub { sinh( _num( $_[0], 0 ) ) },
		cosh => sub { cosh( _num( $_[0], 0 ) ) },
		tanh => sub { tanh( _num( $_[0], 0 ) ) },
		cosech => sub { cosech( _num( $_[0], 0 ) ) },
		sech => sub { sech( _num( $_[0], 0 ) ) },
		cotanh => sub { cotanh( _num( $_[0], 0 ) ) },
		asinh => sub { asinh( _num( $_[0], 0 ) ) },
		acosh => sub { acosh( _num( $_[0], 0 ) ) },
		atanh => sub { atanh( _num( $_[0], 0 ) ) },
		acosech => sub { acosech( _num( $_[0], 0 ) ) },
		asech => sub { asech( _num( $_[0], 0 ) ) },
		acotanh => sub { acotanh( _num( $_[0], 0 ) ) },
	);
	my $trig = native_functions(
		names => \@trig_names,
		builder => sub {
			my ( $name ) = @_;
			my $impl = $trig_impl{$name};
			return sub {
				my ( $self, @args ) = @_;
				return $impl->( @args );
			};
		},
	);

	my $extras = native_functions(
		names => [
			qw(
				pi rand exp log log10 pow min max sum
				clamp hypot deg2rad rad2deg
			)
		],
		builder => sub {
			my ( $name ) = @_;
			return sub {
				my ( $self, @args ) = @_;
				
				if ( @args == 1 and $name =~ /^(?:min|max|sum)$/ and Scalar::Util::blessed($args[0]) ) {
					@args = @{ $args[0]->items };
				}
				
				return pi if $name eq 'pi';
				return @args ? rand( _num( $args[0], 1 ) ) : rand()
					if $name eq 'rand';
				return exp( _num( $args[0], 0 ) )
					if $name eq 'exp';
				if ( $name eq 'log' ) {
					my $value = _num( $args[0], 1 );
					return log($value) if @args < 2;
					my $base = _num( $args[1], 10 );
					return log($value) / log($base);
				}
				return log( _num( $args[0], 1 ) ) / log(10)
					if $name eq 'log10';
				return _num( $args[0], 1 ) ** _num( $args[1], 0 )
					if $name eq 'pow';
				if ( $name eq 'min' ) {
					return 0 if not @args;
					return min( map { _num( $_, 0 ) } @args );
				}
				if ( $name eq 'max' ) {
					return 0 if not @args;
					return max( map { _num( $_, 0 ) } @args );
				}
				return sum( map { _num( $_, 0 ) } @args ) // 0
					if $name eq 'sum';
				if ( $name eq 'clamp' ) {
					my $value = _num( $args[0], 0 );
					my $low = _num( $args[1], 0 );
					my $high = _num( $args[2], 0 );
					return $low if $value < $low;
					return $high if $value > $high;
					return $value;
				}
				if ( $name eq 'hypot' ) {
					my $x = _num( $args[0], 0 );
					my $y = _num( $args[1], 0 );
					return sqrt( $x * $x + $y * $y );
				}
				return _num( $args[0], 0 ) * pi / 180
					if $name eq 'deg2rad';
				return _num( $args[0], 0 ) * 180 / pi
					if $name eq 'rad2deg';

				return undef;
			};
		},
	);

	my %radix_source_base = (
		hex => 16,
		dec => 10,
		oct => 8,
		bin => 2,
	);
	my @radix_names = qw(
		hex2dec hex2oct hex2bin
		dec2hex dec2oct dec2bin
		oct2hex oct2dec oct2bin
		bin2hex bin2dec bin2oct
	);
	my $radix = native_functions(
		names => \@radix_names,
		builder => sub {
			my ( $name ) = @_;
			my ( $from, $to ) = split /2/, $name, 2;
			my $from_base = $radix_source_base{$from};
			my $to_base = $radix_source_base{$to};
			return sub {
				my ( $self, @args ) = @_;
				my $num = _parse_radix_string( $args[0], $from_base, $name );
				return _stringify_radix( $num, $to_base );
			};
		},
	);

	$math_class->static_methods->{$_} = $trig->{$_}
		for @trig_names;
	$math_class->static_methods->{$_} = $extras->{$_}
		for CORE::keys %{ $extras };
	$math_class->static_methods->{$_} = $radix->{$_}
		for @radix_names;

	return {
		Math => $math_class,
		π => pi,
	};
}

1;

=pod

=head1 NAME

Zuzu::Module::Math - std/math bindings for ZuzuScript.

=head1 DESCRIPTION

Implements the C<std/math> module and exports:

=over

=item * C<Math> class with static mathematical helpers

=item * C<π> constant aliasing C<pi>

=back

The C<Math> class provides trigonometric, hyperbolic, logarithmic, and
utility functions such as C<pow>, C<min>, C<max>, C<sum>, C<clamp>,
C<hypot>, C<deg2rad>, and C<rad2deg>. It also provides radix conversion
helpers C<hex2dec>, C<hex2oct>, C<hex2bin>, C<dec2hex>, C<dec2oct>,
C<dec2bin>, C<oct2hex>, C<oct2dec>, C<oct2bin>, C<bin2hex>, C<bin2dec>,
and C<bin2oct>. Hexadecimal parsing accepts an optional C<0x> or C<0X>
prefix.

=head1 COPYRIGHT AND LICENCE

B<< Zuzu::Module::Math >> is copyright Toby Inkster.

It is free software; you may redistribute it and/or modify it under
the terms of either the Artistic License 1.0 or the GNU General Public
License version 2.

=cut
