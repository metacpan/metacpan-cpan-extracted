package Zuzu::Module::Perl;

use utf8;

our $VERSION = '0.003000';

use JSON::PP ();
use Scalar::Util qw( blessed );

use Zuzu::Util::NativeHelpers qw(
	native_class
	native_function
	native_object
	perl_to_zuzu
);

sub _eval_scalar {
	my ( $code, $topic ) = @_;

	$code = defined $code ? "$code" : '';
	my $value;
	if ( @_ > 1 ) {
		local $_ = $topic;
		$value = eval $code;
	}
	else {
		$value = eval $code;
	}
	die $@ if $@;

	return $value;
}

sub _is_safe_perl_value {
	my ( $value, $seen ) = @_;

	return 1 if not defined $value;
	return 1 if not ref $value;
	return 0 if blessed( $value );

	$seen //= {};
	my $addr = "$value";
	return 1 if $seen->{$addr}++;

	if ( ref($value) eq 'ARRAY' ) {
		for my $item ( @{ $value } ) {
			return 0 if not _is_safe_perl_value( $item, $seen );
		}
		return 1;
	}

	if ( ref($value) eq 'HASH' ) {
		for my $key ( CORE::keys %{ $value } ) {
			return 0 if ref $key;
			return 0 if not _is_safe_perl_value( $value->{$key}, $seen );
		}
		return 1;
	}

	return 0;
}

sub _wrap_result {
	my ( $class_obj, $raw ) = @_;

	return native_object(
		class => $class_obj,
		slots => {
			_raw => $raw,
		},
		const => {
			_raw => 1,
		},
	);
}

sub IMPORT {
	my ( $class, $runtime ) = @_;

	my $perl_result_class = native_class(
		name => 'PerlResult',
	);
	my $perl_class = native_class(
		name => 'Perl',
	);

	$perl_class->static_methods->{version} = native_function(
		name => 'version',
		native => sub {
			return "$^V";
		},
	);

	$perl_class->static_methods->{eval} = native_function(
		name => 'eval',
		native => sub {
			my ( $self, $code ) = @_;
			$runtime->assert_capability( 'perl', "Perl.eval is denied by runtime policy" );
			my $value = _eval_scalar( $code );
			return _wrap_result( $perl_result_class, $value );
		},
	);

	$perl_result_class->methods->{isSafe} = native_function(
		name => 'isSafe',
		native => sub {
			my ( $self ) = @_;
			return _is_safe_perl_value( $self->slots->{_raw} ) ? 1 : 0;
		},
	);

	$perl_result_class->methods->{value} = native_function(
		name => 'value',
		native => sub {
			my ( $self ) = @_;
			my $raw = $self->slots->{_raw};
			die "PerlResult is not safe to convert" if not _is_safe_perl_value( $raw );
			return perl_to_zuzu( $raw );
		},
	);

	$perl_result_class->methods->{toJSON} = native_function(
		name => 'toJSON',
		native => sub {
			my ( $self ) = @_;
			my $encoder = JSON::PP->new
				->allow_nonref(1)
				->canonical(1);
			return $encoder->encode( $self->slots->{_raw} );
		},
	);

	$perl_result_class->methods->{eval} = native_function(
		name => 'eval',
		native => sub {
			my ( $self, $code ) = @_;
			$runtime->assert_capability( 'perl', "PerlResult.eval is denied by runtime policy" );
			my $raw = $self->slots->{_raw};
			my $next = _eval_scalar( $code, $raw );
			return _wrap_result( $perl_result_class, $next );
		},
	);

	return {
		Perl => $perl_class,
		PerlResult => $perl_result_class,
	};
}

1;

=pod

=head1 NAME

Zuzu::Module::Perl - perl builtin bridge for ZuzuScript.

=head1 DESCRIPTION

Implements the C<perl> builtin module.

Exports:

=over

=item * C<Perl> class with static methods C<version> and C<eval>

=item * C<PerlResult> class wrapping evaluated Perl values

=back

C<Perl.eval> runs Perl source code in scalar context and always returns
C<PerlResult>.

C<PerlResult> provides:

=over

=item * C<isSafe>

True when the wrapped value contains only undef, scalar, array, and
hash data recursively.

=item * C<value>

Converts the wrapped value to a native Zuzu value. Dies if unsafe.

=item * C<toJSON>

Attempts JSON serialization of the wrapped Perl value.

=item * C<eval>

Evaluates further Perl code with the current result available as C<$_>
in scalar context.

=back

=head1 COPYRIGHT AND LICENCE

B<< Zuzu::Module::Perl >> is copyright Toby Inkster.

It is free software; you may redistribute it and/or modify it under
the terms of either the Artistic License 1.0 or the GNU General Public
License version 2.

=cut
