package Test::URI;
use strict;

use vars qw(@EXPORT $VERSION);

use URI;
use Exporter qw(import);
use Test::Builder;

my $Test = Test::Builder->new();

@EXPORT = qw(uri_scheme_ok uri_host_ok uri_port_ok uri_fragment_ok
	uri_path_ok);

$VERSION = '1.087';

=encoding utf8

=head1 NAME

Test::URI - Check Uniform Resource Identifiers

=head1 SYNOPSIS

	use Test::More tests => 5;
	use Test::URI;

	my $uri = 'http://www.example.com:8080/index.html#name'

	uri_scheme_ok( $uri, 'http' );
	uri_host_ok( $uri, 'www.example.com' );
	uri_port_ok( $uri, '8080' );
	uri_path_ok( $uri, '/index.html' );
	uri_fragment_ok( $uri, 'name' );

=head1 DESCRIPTION

Check various parts of Uniform Resource Locators

=head1 FUNCTIONS

=over 4

=item uri_scheme_ok( STRING|URI, SCHEME )

Ok is the STRING is a valid URI, in any format that
URI accepts, and the URI uses the same SCHEME (i.e.
protocol: http, ftp, ...). SCHEME is not case
sensitive.

STRING can be an URI object.

=cut

sub uri_scheme_ok {
	my $string = shift;
	my $scheme = lc shift;

	my $uri    = ref $string ? $string : URI->new( $string );

	unless( UNIVERSAL::isa( $uri, 'URI' ) ) {
		$Test->ok(0);
		$Test->diag("URI [$string] does not appear to be valid");
		}
	elsif( $uri->scheme ne $scheme ) {
		$Test->ok(0);
		$Test->diag("URI [$string] does not have the right scheme\n",
			"\tExpected [$scheme]\n",
			"\tGot [" . $uri->scheme . "]\n",
			);
		}
	else {
		$Test->ok(1);
		}

	}

=item uri_host_ok( STRING|URI, HOST )

Ok is the STRING is a valid URI, in any format that
URI accepts, and the URI uses the same HOST.  HOST
is not case sensitive.

Not Ok is the URI scheme does not have a host portion.

STRING can be an URI object.

=cut

sub uri_host_ok {
	_methodx_ok( $_[0], $_[1], 'host' );
	}

=item uri_port_ok( STRING|URI, PORT )

Ok is the STRING is a valid URI, in any format that
URI accepts, and the URI uses the same PORT.

Not Ok is the URI scheme does not have a port portion.

STRING can be an URI object.

=cut

my %Portless = map { $_, $_ } qw(mailto file);

sub uri_port_ok
	{
	_methodx_ok( $_[0], $_[1], 'port' );
	}

=item uri_canonical_ok

UNIMPLEMENTED.  I'm not sure why I thought this should be a test.
If anyone else knows, I'll implement it.

=cut

sub uri_canonical_ok {}

=item uri_path_ok( STRING|URI, PATH )

Ok is the STRING is a valid URI, in any format that
URI accepts, and the URI has the path PATH. Remember
that paths start with a /, even if it doesn't look
like there is anything after the host parts.

STRING can be an URI object.

=cut

sub uri_path_ok {
	_methodx_ok( $_[0], $_[1], 'path' );
	}

=item uri_fragment_ok( STRING|URI, FRAGMENT )


Ok is the STRING is a valid URI, in any format that
URI accepts, and the URI has the fragment FRAGMENT.

STRING can be an URI object.

=cut

sub uri_fragment_ok {
	_methodx_ok( $_[0], $_[1], 'fragment' );
	}


sub _methodx_ok {
	my $string   = shift;
	my $expected = shift;
	my $methodx  = lc shift;

	local $Test::Builder::Level = $Test::Builder::Level + 1;

	my $uri    = ref $string ? $string : URI->new( $string );

	unless( UNIVERSAL::isa( $uri, 'URI' ) ) {
		$Test->ok(0);
		$Test->diag("URI [$string] does not appear to be valid");
		}
	elsif( not $uri->can( $methodx ) ) {
		$Test->ok(0);
		my $scheme = $uri->scheme;
		$Test->diag("$scheme schemes do not have a $methodx");
		}
	elsif( $uri->$methodx ne $expected ) {
		$Test->ok(0);
		$Test->diag("URI [$string] does not have the right $methodx\n",
			"\tExpected [$expected]\n",
			"\tGot [" . $uri->$methodx . "]\n",
			);
		}
	else {
		$Test->ok(1);
		}
	}


sub _same_thing_exactly  { $_[0] eq $_[1] }
sub _same_thing_caseless { _same_think_exactly( map { lc } @_ ) }

=back

=head1 TO DO

=over 4

=item * add methods: uri_canonical_ok, uri_query_string_ok

=item * add convenience methods such as uri_is_web, uri_is_ftp

=back

=head1 SOURCE AVAILABILITY

This source is in GitHub

	https://github.com/briandfoy/test-uri

=head1 AUTHOR

brian d foy, C<< <briandfoy@pobox.com> >>

=head1 COPYRIGHT AND LICENSE

Copyright © 2004-2025, brian d foy <briandfoy@pobox.com>. All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the Artistic License 2.0.

=cut

1;
