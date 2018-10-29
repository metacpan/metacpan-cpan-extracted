package WebService::HMRC;

use 5.006;
use strict;
use warnings;

=head1 NAME

WebService::HMRC - Interact with the UK HMRC Making Tax Digital API

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    use WebService::HMRC::Request;

    my $r = WebService::HMRC::Request->new();
    $r->auth->access_token('MY_ACCESS_TOKEN');

    my $response = $r->get_endpoint({
        endpoint => '/hello/user',
        auth_type => 'user',
    });
    print $response->data->{message} if $response->is_success;

=head1 DESCRIPTION

This Perl module is a base for a suite of modules used for
interacting with the HMRC Making Tax Digital (MTD) and Making Tax Digital for
Business (MTDfB) APIs.

HMRC is the UK government tax authority. Their APIs
provide a means to submit and query information relating to personal and
business tax and customs affairs.

These base modules will normally not be used directly by an application.
Instead, applications will generally use a higher-level module which inherits
from these classes.

For more information, see:
L<https://developer.service.hmrc.gov.uk/api-documentation/docs/api>

=head2 CORE MODULES

This module is distributed with the following low-level modules comprising
the essential core classes for interacting with the API:

=over

=item L<WebService::HMRC::Request>

=item L<WebService::HMRC::Response>

=item L<WebService::HMRC::Authenticate>

=back

=head2 API MODULES

Rather than using the low-level modules directly, applications will generally
use a module specific to the API they wish to access (which will inherit from
the core modules). At the time of writing, the following API modules are
available:

=over

=item L<WebService::HMRC::HelloWorld>

=item L<WebService::HMRC::CreateTestUser>

=item L<WebService::HMRC::VAT>

=back

=head1 INSTALLATION

To install this module, run the following commands:

    perl Makefile.PL
    make
    make test
    make install

=head1 AUTHORISATION

Except for a small number of open endpoints, access to the HMRC APIs requires
appliction or user credentials. These must be obtained from HMRC. Application
credentials (and documentation) may be obtained from their
L<Developer Hub|https://developer.service.hmrc.gov.uk/api-documentation>

=head1 TESTING

The basic tests, as run as part of the installation instructions shown above,
do not require an internet connection or authorisation with HMRC.

Developer pre-release tests may be run with the following command:

    prove -l xt/

With a working internet connection and appropriate HMRC credentials, specified
as environment variables, interaction with the real HMRC sandbox api, using
authorisation, may be tested:

=head2 Test generation of a valid authorisation url

To run these tests:

=over

=item * An application must be registered with HMRC.

=item * The application must be enabled for the 'Hello World' test api with HMRC.

=item * C<urn:ietf:wg:oauth:2.0:oob> must be set as a valid redirect_uri for the application.

=item * HMRC_CLIENT_ID environment variable must be set (issued when application was registered).

=item * The HMRC sandbox test api endpoints must be functioning.

=back

    HMRC_CLIENT_ID=[MY-CLIENT-ID] prove -l t/04-hmrc-authenticate.t

This test generates a url, shown in the test output, which can be pasted into
a browser to authorise the application and obtain an Authorisation Code for
the following test stage.

=head2 Test token generation and renewal

In addition to the requirements of the test above, the following environment
variables must be set:

=over

=item * HMRC_CLIENT_SECRET (issued when application was registered).

=item * HMRC_AUTH_CODE (obtained after following the authorisation url generated above).

=back

    HMRC_CLIENT_ID=[MY-CLIENT-ID] \
    HMRC_CLIENT_SECRET=[MY-CLIENT_SECRET] \
    HMRC_AUTH_CODE=[MY-AUTH_CODE] \
    prove -l t/04-hmrc-authenticate.t

When successful, this test will output the response from refreshing access
tokens, including new access and refresh tokens.

=head2 Test API Interaction

These tests query the HMRC Hello World API, testing each of the authentication
types and checking for an expected response. Prerequisites must be in place as
for the other tests above and the following environment variables set:

=over

=item * HMRC_SERVER_TOKEN (issued when application was registered)

=item * HMRC_AUTH_CODE (refreshed code output by previous test above)

=back

    HMRC_SERVER_TOKEN=[MY-SERVER-TOKEN] \
    HMRC_AUTH_CODE=[MY-AUTH_CODE] \
    prove -l t/05-hmrc-api.t

=head1 AUTHOR

Nick Prater, <nick@npbroadcast.com>

=head1 BUGS

Please report any bugs or feature requests to C<bug-webservice-hmrc@rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WebService-HMRC>.
I will be notified, and then you'll automatically be notified of progress on your bug as
I make changes.

=head1 SUPPORT AND DOCUMENTATION

After installation, you can find documentation for this module with the
perldoc command.

    perldoc WebService::HMRC

The C<README.pod> file supplied with this distribution is generated from the
L<WebService::HMRC> module's pod by running the following command from the 
distribution root:

    perldoc -u lib/WebService/HMRC.pm > README.pod

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=WebService-HMRC>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/WebService-HMRC>

=item * Search CPAN

L<https://search.cpan.org/dist/WebService-HMRC/>

=item * GitHub

L<https://github.com/nick-prater/WebService-HMRC>

=back

=head1 ACKNOWLEDGEMENTS

This module was originally developed for use as part of the
L<LedgerSMB|https://ledgersmb.org/> open source accounting software.

=head1 LICENSE AND COPYRIGHT

Copyright 2018 Nick Prater, NP Broadcast Limited.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

1; # End of WebService::HMRC
