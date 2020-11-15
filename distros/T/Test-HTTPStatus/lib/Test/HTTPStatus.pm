package Test::HTTPStatus;
use strict;

use warnings;
no warnings;

=encoding utf8

=head1 NAME

Test::HTTPStatus - check an HTTP status

=head1 SYNOPSIS

	use Test::HTTPStatus tests => 2;
	use Apache::Constants qw(:http);

	http_ok( 'https://www.perl.org', HTTP_OK );

	http_ok( $url, $status );

=head1 DESCRIPTION

Check the HTTP status for a resource.

=cut

use v5.10.1;  # Mojolicious is v5.10.1 and later
our $VERSION = '2.05';

use parent 'Test::Builder::Module';

use Carp qw(carp);
use HTTP::SimpleLinkChecker;
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

=over 4

=item http_ok( URL [, HTTP_STATUS] )

Print the ok message if the URL's HTTP status matches the specified
HTTP_STATUS.  If you don't specify a status, it assumes you mean
HTTP_OK (from Apache::Constants).

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

sub _get_status {
	my $string = shift;

	return { status => NO_URL } unless defined $string;

	my $url = Mojo::URL->new( $string );
	return { status => undef } unless $url->host;

	my $status = HTTP::SimpleLinkChecker::check_link( $url );

	return { url => $url, status => $status };
	}

=back

=head1 SEE ALSO

L<Apache::Constants>, L<HTTP::SimpleLinkChecker>

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

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Test-HTTPStatus>

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
