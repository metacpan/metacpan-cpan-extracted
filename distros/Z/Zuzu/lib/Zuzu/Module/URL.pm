package Zuzu::Module::URL;

use utf8;

our $VERSION = '0.001003';

use URI ();
use URI::Escape qw( uri_escape_utf8 uri_unescape );

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

sub _template_var {
	my ( $data, $name ) = @_;

	return '' if not exists $data->{$name};
	return '' if not defined $data->{$name};
	return uri_escape_utf8( _str( $data->{$name}, '' ) );
}

sub _template_query {
	my ( $data, $names ) = @_;

	my @parts;
	for my $name ( split /\s*,\s*/, $names ) {
		next if $name eq '';
		next if not exists $data->{$name};
		next if not defined $data->{$name};
		my $key = uri_escape_utf8($name);
		my $val = uri_escape_utf8( _str( $data->{$name}, '' ) );
		push @parts, "$key=$val";
	}

	return '' if scalar @parts == 0;
	return '?' . join '&', @parts;
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

	my $out = _str( $template, '' );
	my $data = _hash_from( $values );

	$out =~ s/\{\?([^}]+)\}/_template_query( $data, $1 )/ge;
	$out =~ s/\{([a-zA-Z_][a-zA-Z0-9_]*)\}/_template_var( $data, $1 )/ge;

	return $out;
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
