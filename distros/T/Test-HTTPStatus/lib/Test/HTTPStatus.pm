package Test::HTTPStatus;
use strict;

use warnings;
# no warnings;

=encoding utf8

=head1 NAME

Test::HTTPStatus - check an HTTP status

=head1 SYNOPSIS

	use Test::HTTPStatus tests => 2;

	http_ok( 'https://www.perl.org', HTTP_OK );

	http_ok( $url, $status );

=head1 DESCRIPTION

Check the HTTP status for a resource.

=cut

use v5.10.1;  # Mojolicious is v5.10.1 and later
our $VERSION = '2.07';

use parent 'Test::Builder::Module';

use Carp qw(carp);
# use HTTP::SimpleLinkChecker;
use Mojo::UserAgent;
use Test::Builder::Module;
use Mojo::URL;

my $Test = __PACKAGE__->builder;

use constant NO_URL             =>  -1;
use constant INVALID_URL        =>  -2;
use constant HTTP_OK            => 200;
use constant HTTP_NOT_FOUND     => 404;

sub import {
    my $self = shift;
    my $caller = caller;
    no strict 'refs';
    *{$caller.'::http_ok'}         = \&http_ok;
    *{$caller.'::NO_URL'}          = \&NO_URL;
    *{$caller.'::INVALID_URL'}     = \&INVALID_URL;
    *{$caller.'::HTTP_OK'}         = \&HTTP_OK;
    *{$caller.'::HTTP_NOT_FOUND'}  = \&HTTP_NOT_FOUND;

    $Test->exported_to($caller);
    $Test->plan(@_);
	}

=head1 FUNCTIONS

=head2 http_ok( URL [, HTTP_STATUS ] )

    http_ok( $url, $expected_status );

Tests the HTTP status of the specified URL and reports whether it matches the expected status.

=head3 Parameters

=over 4

=item * C<URL> (Required)

The URL to be tested.
This must be a valid URL string.
If the URL is invalid or undefined, the test will fail, and an appropriate diagnostic message will be displayed.

=item * C<HTTP_STATUS> (Optional)

The expected HTTP status code.
Defaults to C<HTTP_OK> (200) if not provided.
This parameter should be one of the HTTP status constants exported by the module (e.g., C<HTTP_OK>, C<HTTP_NOT_FOUND>).

=back

=head3 Diagnostics

On success, the test will pass with a message in the following format:

    Expected [<expected_status>], got [<actual_status>] for [<url>]

On failure, the test will fail with one of the following messages:

=over 4

=item * C<[$url] does not appear to be anything>

Indicates that the URL was undefined or missing.

=item * C<[$url] does not appear to be a valid URL>

Indicates that the URL string provided was invalid or malformed.

=item * C<Mysterious failure for [$url] with status [$status]>

Indicates that the request failed for an unexpected reason or returned a status not matching the expected value.

=back

=head3 Examples

=over 4

=item * Basic test with default expected status:

    http_ok('https://www.perl.org');

This checks that the URL C<https://www.perl.org> returns an HTTP status of C<HTTP_OK> (200).

=item * Test with a custom expected status:

    http_ok('https://www.example.com/404', HTTP_NOT_FOUND);

This checks that the URL C<https://www.example.com/404> returns an HTTP status of C<HTTP_NOT_FOUND> (404).

=back

=head3 Return Value

The routine does not return any value.
Instead, it reports success or failure using the underlying test builder's C<ok> method.

=cut

sub http_ok {
	my $url      = shift;
	my $expected = shift || HTTP_OK;

	my $hash = _get_status( $url );

	my $status = $hash->{status};

	if( defined $expected and $expected eq $status ) {
		$Test->ok( 1, "Expected [$expected], got [$status] for [$url]" );
		}
	elsif( $status == NO_URL ) {
		$Test->ok( 0, "[$url] does not appear to be anything" );
		}
	elsif( $status == INVALID_URL ) {
		$Test->ok( 0, "[$url] does not appear to be a valid URL" );
		}
	else {
		$Test->ok( 0, "Mysterious failure for [$url] with status [$status]" );
		}
	}

my $UA ||= Mojo::UserAgent->new();
$UA->proxy->detect();
$UA->max_redirects(3);

sub _get_status {
	my $string = shift;

	return { status => NO_URL } unless defined $string;

	my $url = Mojo::URL->new( $string );
	return { status => undef } unless $url->host;

	my $status = _check_link( $url );

	return { url => $url, status => $status };
	}

# From HTTP::SimpleLinkChecker, which has been deleted
sub _check_link {
	my( $link ) = @_;
	say STDERR "Link is $link";
	unless( defined $link ) {
		# $ERROR = 'Received no argument';
		return;
		}

	my $transaction = $UA->head($link);
	my $response = $transaction->res;

	if( !($response and $response->code >= 400) ) {
		$transaction = $UA->get($link);
		$response = $transaction->res;
		}

	unless( ref $response ) {
		# $ERROR = 'Could not get response';
		return;
		}

	return $response->code;
	}

=head1 SEE ALSO

L<HTTP::SimpleLinkChecker>, L<Mojo::URL>

=head1 AUTHORS

brian d foy, C<< <bdfoy@cpan.org> >>

Maintained by Nigel Horne, C<< <njh at bandsman.co.uk> >>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::HTTPStatus

You can also look for information at:

=over 4

=item * MetaCPAN

L<https://metacpan.org/release/Test-HTTPStatus>

=item * RT: CPAN's request tracker

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Test-HTTPStatus>

=item * CPANTS

L<http://cpants.cpanauthors.org/dist/Test-HTTPStatus>

=item * CPAN Testers' Matrix

L<http://matrix.cpantesters.org/?dist=Test-HTTPStatus>

=item * CPAN Testers Dependencies

L<http://deps.cpantesters.org/?module=Test::HTTPStatus>

=back

=head1 LICENSE AND COPYRIGHT

This program is released under the following licence: GPL2
Copyright © 2002-2019, brian d foy <bdfoy@cpan.org>. All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the Artistic License 2.0.

=cut

1;
