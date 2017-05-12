=head1 NAME

WWW::Mechanize::Cached::GZip - like WWW::Mechanize + caching + gzip-compression 

=head1 VERSION

Version 0.12

=head1 SYNOPSIS

    use WWW::Mechanize::Cached::GZip;

    my $mech_cached = WWW::Mechanize::Cached::GZip->new();
    my $response = $mech_cached->get($url);

    print "x-content-length (before unzip) = ", $response->header('x-content-length');
    print "content-length (after unzip) = ", $response->header('content-length');

    ...
    
    # for the same $url - the already uncompressed $response2 is now taken from cache:
    my $response2 = $mech_cached->get($url); 

=head1 DESCRIPTION

The L<WWW::Mechanize::Cached::GZip> module tries to fetch a URL by requesting
gzip-compression from the webserver.

Caching is done by inheriting from L<WWW::Mechanize::Cached>.
Constructor parameters are identically and described there.

=head2 DECOMPRESSION

If the response contains a header with 'Content-Encoding: gzip', it
decompresses the response-body in order to get the original (uncompressed) content.

This module will help to reduce bandwith fetching webpages, if supported by the
webeserver. If the webserver does not support gzip-compression, no decompression
will be made.

The decompression of the response is handled by L<Compress::Zlib>::memGunzip.

There is a small webform, you can instantly test, whether a webserver supports
gzip-compression on a particular URL:
L<http://www.computerhandlung.de/www-mechanize-cached-gzip.htm>

=head2 CACHING

This modules is a direct subclass of L<WWW::Mechanize::Cached> and will therefore
accept the same constructor parameters and support any methods provided
by WWW::Mechanize::Cached.

The default behavoir is to use Cache::FileCache which stores its files somewhere
under /tmp.

=head2 METHODS

=over 2

=item prepare_request

Adds 'Accept-Encoding' => 'gzip' to outgoing HTTP-headers before sending.

=item send_request

Unzips response-body if 'content-encoding' is 'gzip' and
corrects 'content-length' to unzipped content-length.

=back

=head1 SEE ALSO

L<WWW::Mechanize::Cached>

L<Compress::Zlib>

=head1 AUTHOR

Peter Giessner C<cardb@planet-elektronik.de>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2011, Peter Giessner C<cardb@planet-elektronik.de>.
All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

package WWW::Mechanize::Cached::GZip;

our $VERSION = '0.12';

use Moose;
extends 'WWW::Mechanize::Cached';
use WWW::Mechanize::GZip;

################################################################################
sub prepare_request {
    my ($self, $request) = @_;
    
    # call sideclass-method to prepare request
    return WWW::Mechanize::GZip::prepare_request($self, $request);
}

################################################################################
sub send_request {
    my ($self, $request, $arg, $size) = @_;

    # call sideclass-method to make the actual request
    return WWW::Mechanize::GZip::send_request($self, $request, $arg, $size);
}

1;

__END__