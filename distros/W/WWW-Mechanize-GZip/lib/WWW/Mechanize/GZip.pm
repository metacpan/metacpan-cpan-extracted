=head1 NAME

WWW::Mechanize::GZip - tries to fetch webpages with gzip-compression

=head1 VERSION

Version 0.10

=head1 SYNOPSIS

    use WWW::Mechanize::GZip;

    my $mech = WWW::Mechanize::GZip->new();
    my $response = $mech->get( $url );

    print "x-content-length (before unzip) = ", $response->header('x-content-length');
    print "content-length (after unzip) = ", $response->header('content-length');

=head1 DESCRIPTION

The L<WWW::Mechanize::GZip> module tries to fetch a URL by requesting
gzip-compression from the webserver.

If the response contains a header with 'Content-Encoding: gzip', it
decompresses the response in order to get the original (uncompressed) content.

This module will help to reduce bandwith fetching webpages, if supported by the
webeserver. If the webserver does not support gzip-compression, no decompression
will be made.

This modules is a direct subclass of L<WWW::Mechanize> and will therefore support
any methods provided by L<WWW::Mechanize>.

The decompression is handled by L<Compress::Zlib>::memGunzip.

There is a small webform, you can instantly test, whether a webserver supports
gzip-compression on a particular URL:
L<http://www.computerhandlung.de/www-mechanize-gzip.htm>

=head2 METHODS

=over 2

=item prepare_request

Adds 'Accept-Encoding' => 'gzip' to outgoing HTTP-headers before sending.

=item send_request

Unzips response-body if 'content-encoding' is 'gzip' and
corrects 'content-length' to unzipped content-length.

=back

=head1 SEE ALSO

L<WWW::Mechanize>

L<Compress::Zlib>

=head1 AUTHOR

Peter Giessner C<cardb@planet-elektronik.de>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007, Peter Giessner C<cardb@planet-elektronik.de>.
All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

package WWW::Mechanize::GZip;

our $VERSION = '0.12';

use strict;
use warnings;
use Compress::Zlib ();
use base qw(WWW::Mechanize);

################################################################################
sub prepare_request {
    my ($self, $request) = @_;

    # call baseclass-method to prepare request...
    $request = $self->SUPER::prepare_request($request);

    # set HTTP-header to request gzip-transfer-encoding at the webserver
    $request->header('Accept-Encoding' => 'gzip');

    return ($request);
}

################################################################################
sub send_request {
    my ($self, $request, $arg, $size) = @_;

    # call baseclass-method to make the actual request
    my $response = $self->SUPER::send_request($request, $arg, $size);

    # check if response is declared as gzipped and decode it
    if ($response && defined($response->headers->header('content-encoding')) && $response->headers->header('content-encoding') eq 'gzip') {
        # store original content-length in separate response-header
        $response->headers->header('x-content-length', length($response->{_content}));
        # decompress ...
        $response->{_content} = Compress::Zlib::memGunzip(\($response->{_content}));
        # store new content-length in response-header
        $response->{_headers}->{'content-length'} = length($response->{_content});
    }
    return $response;
}

1;

__END__