package WebService::HMRC::HelloWorld;

use 5.006;
use Moose;
use namespace::autoclean;

extends 'WebService::HMRC::Request';

=head1 NAME

WebService::HMRC::HelloWorld - Interact with the UK HMRC HelloWorld API

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    use WebService::HMRC::HelloWorld;
    my $hmrc = WebService::HMRC::HelloWorld->new();

    # Hello World endpoint requires no authorisation
    my $result = $hmrc->hello_world()
    print $result->data->{message} if $result->is_success;

    # Hello Application endpoint requires a server token
    $hmrc->auth->server_token( $my_server_token );
    $result = $hmrc->hello_application();
    print $result->data->{message} if $result->is_success;

    # Hello User endpoint requires an access token
    $hmrc->auth->access_token( $my_access_token );
    $result = $hmrc->hello_user();
    print $result->data->{message} if $result->is_success;

=head1 DESCRIPTION

Perl module to interact with the UK's HMRC Making Tax Digital
`Hello World` API. This is often used as a basic test of configuration
and credentials before using their more involved APIs for managing
corporate and personal tax affairs.

For more information, see:
L<https://developer.service.hmrc.gov.uk/api-documentation/docs/api/service/api-example-microservice/1.0>

=head1 REQUIRES

=over

=item L<WebService::HMRC>

=back

=head1 EXPORTS

Nothing   
   
=head1 PROPERTIES

Inherits from L<WebService::HMRC::Request>.

=head1 METHODS

Inherits from L<WebService::HMRC::Request>.

=head2 hello_world()

Retrieve a "Hello World" message. Does not require authorisation.

Returns a WebService::HMRC::Response object.

=cut

sub hello_world {

    my $self = shift;

    return $self->get_endpoint({
        endpoint => '/hello/world',
    });
}


=head2 hello_application()

Retrieve a "Hello Application" message. This is an application-restricted
endpoint which requires that this module's server_token property be set.

Returns a WebService::HMRC::Response object.

=cut

sub hello_application {

    my $self = shift;

    return $self->get_endpoint({
        endpoint => '/hello/application',
        auth_type => 'application',
    });
}


=head2 hello_user()

Retrieve a "Hello User" message. This is a user-restricted endpoint
requiring permission for the C<hello> service scope.

Returns a WebService::HMRC::Response object.

=cut

sub hello_user {

    my $self = shift;

    return $self->get_endpoint({
        endpoint => '/hello/user',
        auth_type => 'user',
    })
}

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

Access to the HMRC C<Hello World> service requires that an application
be registered with HMRC and 'subscribed' for this api.

This module allows all three of the possible authorisation types to be
exercised.

The C<hello_world()> method accesses an 'open' endpoint and does not
require authorisation.

The C<hello_application()> method accesses an 'application-restricted'
endpoint and therefore requires a C<server token> for authorisation. This is
issued when the application is registered with HMRC and may be retrieved
from the HMRC Developer Hub.

The C<hello_user()> method accesses a 'user-restricted' endpoint and
therefore requires an C<access token> for authorisation, obtained when
a user grants permission to the application for the C<hello> service scope.

For more details on obtaining and using access tokens, See
L<WebService::HMRC::Authenticate>.

Further information, application credentials and documentation may be obtained
from the
L<HMRC Developer Hub|https://developer.service.hmrc.gov.uk/api-documentation>.

=head1 TESTING

The basic tests are run as part of the installation instructions shown above
and do not require authorisation with HMRC. A call will be made to the open
C</hello/world> api endpoint, which requires a working internet connection
and that the HMRC sandbox test environment is operational.

Developer pre-release tests may be run with the following command:

    prove -l xt/

With a working internet connection and appropriate HMRC credentials, specified
as environment variables, interaction with the protected C<HelloWorld> endpoints
can be tested:

=over

=item * Test access to an application-restricted endpoint:

    HMRC_SERVER_TOKEN=[MY-SERVER-TOKEN] make test TEST_VERBOSE=1

=item * Test access to a user-restricted endpoint:

    HMRC_ACCESS_TOKEN=[MY-SERVER-TOKEN] make test TEST_VERBOSE=1

=back

=head1 AUTHOR

Nick Prater, <nick@npbroadcast.com>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-webservice-hmrc-helloworld at rt.cpan.org>, or through
the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WebService-HMRC-HelloWorld>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WebService::HMRC::HelloWorld

The C<README.pod> file supplied with this distribution is generated from the
L<WebService::HMRC::HelloWorld> module's pod by running the following
command from the distribution root:

    perldoc -u lib/WebService/HMRC/HelloWorld.pm > README.pod

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WebService-HMRC-HelloWorld>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WebService-HMRC-HelloWorld>

=item * Search CPAN

L<http://search.cpan.org/dist/WebService-HMRC-HelloWorld/>

=item * Github

L<https://github.com/nick-prater/WebService-HMRC-HelloWorld>

=back

=head1 ACKNOWLEDGEMENTS

This module was originally developed for use as part of the
L<LedgerSMB|https://ledgersmb.org/> open source accounting software.

=head1 LICENSE AND COPYRIGHT

Copyright 2018 Nick Prater, NP Broadcast Ltd.

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

__PACKAGE__->meta->make_immutable;
1; # End of WebService::HMRC::HelloWorld
