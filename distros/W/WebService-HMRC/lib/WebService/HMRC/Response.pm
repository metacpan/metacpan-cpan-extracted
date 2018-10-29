package WebService::HMRC::Response;

use 5.006;
use Carp;
use JSON::MaybeXS qw(decode_json);
use Moose;
use namespace::autoclean;
use Try::Tiny;


=head1 NAME

WebService::HMRC::Response - Response object for the UK HMRC MTD API

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    use WebService::HMRC::HelloWorld;  # inherits this module
    my $hmrc = WebService::HMRC::HelloWorld->new();

    # Hello World endpoint requires no authorisation
    # It returns a WebService::HMRC::Response object reference
    my $hmrc_response = $hmrc->hello_world()

    print "success\n" if $hmrc_response->is_success();

    my $status_code  = $hmrc_response->http->code;
    my $message      = $hmrc_response->data->{message};
    my $content_type = $hmrc_response->header('content-type');

=head1 DESCRIPTION

This is part of the L<WebService::HMRC> suite of Perl modules for
interacting with the UK's HMRC Making Tax Digital APIs.

This class represents the response from an api call. It is inherited by
other classes which implement bindings to HMRC APIs rather than being
used directly.

=head1 INSTALLATION AND TESTING

See documentation for L<WebService::HMRC>.
   
=head1 PROPERTIES

=head2 data

Reference to a perl hash representing an api call's json response.

This property is updated on object creation when the http property is set.

If an api call returns no valid json response, this property is
populated with a dummy response, in the same format as the standard
HRMC error response, with code 'INVALID_RESPONSE'. This facilitates
consistent error parsing by the calling application.

=cut

has data => (
    is => 'rw',
    isa => 'Maybe[HashRef]',
    default => undef,
);

=head2 http

The raw HTTP::Response object resulting from an api call. See documentation
for L<HTTP::Response>.

=cut

has http => (
    is => 'ro',
    isa => 'HTTP::Response',
    required => 1,
    trigger => \&_parse_http_response,
    handles => ['is_success', 'header'],
);


=head1 METHODS

=head2 is_success()

Shortcut to the HTTP::Response is_success method.

=head2 header($header_name)

Returns the value of the specified response header, or undef if it does
not exist. Shortcut to the HTTP::Response header method.

=cut


# PRIVATE METHODS

# _parse_http_response($http_response)
#
# Update this class's `data` property to reflect the json content of
# the supplied HTTP::Response object. Returns a reference to the Perl data
# structure representing the json response.

sub _parse_http_response {
    my $self = shift;
    my $http = shift;

    # Under normal conditions, the api always returns json content
    # even for error responses. But unusual error conditions could
    # return content that is invalid json, which will cause the parser
    # to croak. We therefore wrap it in a `try` block.
    my $data = try {
        return decode_json($http->decoded_content);
    }
    catch {
        carp "unable to parse api response as json: $_";

        # Create dummy error message with same format as HMRC
        # error response to facilitate consistent error parsing by
        # calling application.
        return {
            code    => 'INVALID_RESPONSE',
            message => 'No valid JSON data received from api call. '.
                       $http->status_line,
        };
    };

    $self->data($data);
    return $data;
}


=head1 AUTHOR

Nick Prater <nick@npbroadcast.com>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-webservice-hmrc-helloworld@rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WebService-HMRC>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WebService::HMRC::Response


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WebService-HMRC>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WebService-HMRC>

=item * Search CPAN

L<http://search.cpan.org/dist/WebService-HMRC/>

=item * GitHub

L<https://github.com/nick-prater/WebService-HMRC>

=back

=head1 ACKNOWLEDGEMENTS

This module was originally developed for use as part of the
L<LedgerSMB|https://ledgersmb.org/> open source accounting software.

=head1 LICENCE AND COPYRIGHT

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

__PACKAGE__->meta->make_immutable;
1;
