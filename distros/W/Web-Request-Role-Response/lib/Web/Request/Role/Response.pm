package Web::Request::Role::Response;

# ABSTRACT: Generate various HTTP responses from a Web::Request

our $VERSION = '1.005';

use 5.010;
use Moose::Role;
use Web::Response;

sub redirect {
    my ( $self, $target, $status ) = @_;

    if ( ref($target) eq 'HASH' ) {
        $target = $self->uri_for($target);
    }
    my $res = $self->new_response();
    $res->redirect( $target, $status );
    $res->content("Redirecting to: $target");
    return $res;
}

sub permanent_redirect {
    my ( $self, $target ) = @_;

    return $self->redirect( $target, 301 );
}

sub file_download_response {    # TODO make it stream?
    my ( $self, $content_type, $data, $filename ) = @_;

    return Web::Response->new(
        status  => 200,
        headers => [
            'content_type'        => $content_type,
            'content_disposition' => 'attachment; filename=' . $filename
        ],
        content => $data,
    );
}

sub no_content_response {
    my $self = shift;

    return $self->new_response( status => 204, );
}

my $transparent_gif = pack( 'H*',
    '47494638396101000100800000000000ffffff21f90401000000002c000000000100010000020144003b'
);

sub transparent_gif_response {
    my $self = shift;

    # cannot use $self->new_reponse here, because this would reuse the
    # encoding_object of the request, which will mangle the binary
    # response

    return Web::Response->new(
        status  => 200,
        headers => [
            'content-type'   => 'image/gif',
            'content-length' => length($transparent_gif),
        ],
        content => $transparent_gif,
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Web::Request::Role::Response - Generate various HTTP responses from a Web::Request

=head1 VERSION

version 1.005

=head1 SYNOPSIS

  # Create a request handler
  package My::App::Request;
  use Moose;
  extends 'Web::Request';
  with 'Web::Request::Role::Response';

  # Make sure your app uses your request handler, e.g. using OX:
  package My::App::OX;
  sub request_class {'My::App::Request'}

  # in some controller action:

  # redirect
  $req->redirect('/');
  $req->permanent_redirect('/foo');

  # return 204 no content
  $req->no_content_response;

  # return a transparent 1x1 gif (eg as a tracking pixle)
  $req->transparent_gif_response;

  # file download
  $req->file_download_response( 'text/csv', $data, 'your_export.csv' );

=head1 DESCRIPTION

C<Web::Request::Role::JSON> provides a few methods that make generating HTTP responses easier when using L<Web::Request>.

Please note that all methods return a L<Web::Response> object.
Depending on the framework you use (or lack thereof), you might have
to call C<finalize> on the response object to turn it into a valid
PSGI response.

=head2 METHODS

=head3 redirect

  $req->redirect( '/some/location' );
  $req->redirect( $ref_uri_for );
  $req->redirect( 'http://example.com', 307 );

Redirect to the given location. The location can be a string
representing an absolute or relative URL. You can also pass a ref,
which will be resolved by calling C<uri_for> on the request object -
so be sure that your request object has this method (extra points if
the method also returns something meaningful)!

You can pass a HTTP status code as a second parameter. It's probably
smart to use one that makes sense in a redirecting context...

=head3 permanent_redirect

  $req->permanent_redirect( 'http://we.moved.here' );

Similar to C<redirect>, but will issue a permanent redirect (who would
have thought!) using HTTP status code C<301>.

=head3 file_download_response

  $req->file_download_response( $content-type, $data, $filename );

Generate a "Download-File" response. Useful if your app returns a
CSV/Spreadsheet/MP3 etc. You have to provide the correct content-type,
the data in the correct encoding and a meaningful filename.

=head3 no_content_response

  $req->no_content_response

Returns C<204 No Content>.

=head3 transparent_gif_response

  $req->transparent_gif_response

Returns a transparent 1x1 pixel GIF. Useful as the response of a
tracking URL.

=head1 THANKS

Thanks to

=over

=item *

L<validad.com|https://www.validad.com/> for supporting Open Source.

=back

=head1 AUTHOR

Thomas Klausner <domm@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 - 2019 by Thomas Klausner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
