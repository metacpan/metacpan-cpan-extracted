package Zuzu::Module::URL;

use utf8;

our $VERSION = '0.005000';

use Scalar::Util qw( blessed );
use URI ();
use URI::Escape qw( uri_escape_utf8 uri_unescape );
use URI::Template ();

use Zuzu::Error;

use Zuzu::Util::NativeHelpers qw(
	native_function
	perl_to_zuzu
	zuzu_to_perl
);

sub _str {
	my ( $value, $default ) = @_;

	return $default if not defined $value;
	return "$value";
}

sub _hash_from {
	my ( $value ) = @_;

	return {} if not defined $value;
	my $perl = zuzu_to_perl( $value );
	return {} if ref($perl) ne 'HASH';
	return $perl;
}

# RFC 6570 expression grammar: optional operator, then a comma list of
# varspecs (varname with optional :N prefix or * explode modifier).
my $TEMPLATE_VARCHAR = qr/(?:[A-Za-z0-9_]|%[0-9A-Fa-f]{2})/;
my $TEMPLATE_VARSPEC =
	qr/$TEMPLATE_VARCHAR(?:\.?$TEMPLATE_VARCHAR)*(?::[1-9][0-9]{0,3}|\*)?/;

sub _die_template {
	my ( $source ) = @_;

	die Zuzu::Error->new_runtime(
		message => "invalid URL template: $source",
		file => '<std/net/url>',
		line => 0,
	);
}

sub _validate_template {
	my ( $source, $data ) = @_;

	my $rest = $source;
	while ( length $rest ) {
		my $open = index( $rest, '{' );
		my $close = index( $rest, '}' );
		last if $open < 0 and $close < 0;
		_die_template( $source ) if $open < 0;
		_die_template( $source ) if $close < 0 or $close < $open;
		my $expression = substr( $rest, $open + 1, $close - $open - 1 );
		_die_template( $source )
			if $expression !~ /\A[+#.\/;?&]?$TEMPLATE_VARSPEC(?:,$TEMPLATE_VARSPEC)*\z/;
		# The :N prefix modifier only applies to string values; using it
		# with a list or associative value is an expansion failure.
		( my $specs = $expression ) =~ s/\A[+#.\/;?&]//;
		for my $spec ( split /,/, $specs ) {
			if ( $spec =~ /\A(.*):[1-9][0-9]{0,3}\z/ ) {
				_die_template( $source ) if ref $data->{$1};
			}
		}
		$rest = substr( $rest, $close + 1 );
	}
}

sub _template_value {
	my ( $value ) = @_;

	return undef if not defined $value;
	if ( blessed($value) and $value->isa('Zuzu::Value::Boolean') ) {
		return $value->value ? 'true' : 'false';
	}
	if ( ref($value) eq 'ARRAY' ) {
		# RFC 6570: a zero-member list is undefined.
		return undef if not @{$value};
		return [ map { _str( $_, '' ) } @{$value} ];
	}
	if ( ref($value) eq 'HASH' ) {
		# RFC 6570: a zero-member associative array is undefined.
		return undef if not keys %{$value};
		return { map { $_ => _str( $value->{$_}, '' ) } keys %{$value} };
	}
	return _str( $value, '' );
}

sub _parse_url {
	my ( $value ) = @_;

	my $text = _str( $value, '' );
	my $uri  = URI->new( $text );
	my %query = $uri->query_form;

	return {
		url => $uri->as_string,
		scheme => scalar $uri->scheme,
		authority => scalar $uri->authority,
		userinfo => scalar $uri->userinfo,
		host => scalar $uri->host,
		port => scalar $uri->port,
		path => scalar $uri->path,
		query => scalar $uri->query,
		fragment => scalar $uri->fragment,
		query_params => \%query,
	};
}

sub _fill_template {
	my ( $template, $values ) = @_;

	my $source = _str( $template, '' );
	my $raw = _hash_from( $values );
	my %data;
	for my $key ( keys %{$raw} ) {
		my $converted = _template_value( $raw->{$key} );
		$data{$key} = $converted if defined $converted;
	}
	_validate_template( $source, \%data );

	return URI::Template->new( $source )->process_to_string( %data );
}

sub IMPORT {
	my ( $class, $runtime ) = @_;

	my $escape_fn = native_function(
		name => 'escape',
		native => sub {
			my ( $value ) = @_;
			return uri_escape_utf8( _str( $value, '' ) );
		},
	);

	my $unescape_fn = native_function(
		name => 'unescape',
		native => sub {
			my ( $value ) = @_;
			return uri_unescape( _str( $value, '' ) );
		},
	);

	my $parse_fn = native_function(
		name => 'parse',
		native => sub {
			my ( $url ) = @_;
			return perl_to_zuzu( _parse_url( $url ) );
		},
	);

	my $fill_template_fn = native_function(
		name => 'fill_template',
		native => sub {
			my ( $template, $values ) = @_;
			return _fill_template( $template, $values );
		},
	);

	return {
		escape => $escape_fn,
		unescape => $unescape_fn,
		parse => $parse_fn,
		fill_template => $fill_template_fn,
	};
}

1;

=pod

=head1 NAME

Zuzu::Module::URL - std/net/url bindings for ZuzuScript.

=head1 DESCRIPTION

Implements the C<std/net/url> module and exports four functions:
C<escape>, C<unescape>, C<parse>, and C<fill_template>.

=head1 COPYRIGHT AND LICENCE

B<< Zuzu::Module::URL >> is copyright Toby Inkster.

It is free software; you may redistribute it and/or modify it under
the terms of either the Artistic License 1.0 or the GNU General Public
License version 2.

=cut
