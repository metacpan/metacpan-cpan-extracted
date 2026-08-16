#
#  This file is part of WebDyne.
#
#  This software is copyright (c) 2026 by Andrew Speer <andrew.speer.com.au>.
#
#  This is free software; you can redistribute it and/or modify it under
#  the same terms as the Perl 5 programming language system itself.
#
#  Full license text is available at:
#
#  <http://dev.perl.org/licenses/>
#
package WebDyne::Request::PSGI::Static;


#  Compiler Pragma
#
use strict qw(vars);
use vars   qw($VERSION $AUTOLOAD @ISA);


#  External modules
#
use HTTP::Status (qw(HTTP_INTERNAL_SERVER_ERROR HTTP_NOT_FOUND HTTP_OK));
use IO::File;
use WebDyne::Util;
use WebDyne::Constant;


#  Inheritance
#
use WebDyne::Request::PSGI;
@ISA=qw(WebDyne::Request::PSGI);


#  Version information
#
$VERSION='3.014';


#  Debug load
#
debug("Loading %s version $VERSION", __PACKAGE__);


#  All done. Positive return
#
1;


#==================================================================================================


sub run {

    my $r_child=shift();
    my $r=$r_child->prev();
    my $fn=$r_child->filename();
    debug("in WebDyne::Request::PSGI::Static, r: $r, fn: $fn");
    if (!-f $fn) {
        warn("file '$fn' not found");
        return $r->status(HTTP_NOT_FOUND);
    }
    elsif (my $fh=IO::File->new($fn, O_RDONLY)) {
        my $hr=$r->headers_out();
        my $size=(stat($fn))[7];
        $hr->{'Content-Length'}=$size;
        my $ext=($fn=~/\.(\w+)$/) && $1;
        $hr->{'Content-Type'}=$WEBDYNE_MIME_TYPE_HR->{$ext} || $WEBDYNE_CONTENT_TYPE_TEXT;
        $r->send_http_header();
        my $buf;
        while (read($fh, $buf, 8192)) {$r->print($buf)}
        $fh->close();
        return HTTP_OK
    }
    else {
        warn("unable to open file '$fn', $!");
        return $r->status(HTTP_INTERNAL_SERVER_ERROR);
    }

}
__END__

=begin markdown

# WebDyne::Request::PSGI::Static #

# NAME #

WebDyne::Request::PSGI::Static - simple static-file responder for WebDyne PSGI request flows

# SYNOPSIS #

```perl
use WebDyne::Request::PSGI::Static;

my $status = WebDyne::Request::PSGI::Static->run($child_request);
```

# DESCRIPTION #

`WebDyne::Request::PSGI::Static` is a small helper subclass used when a PSGI request should serve a static asset rather than a `.psp` page.

It reads the nominated file, sets `Content-Length`, selects a content type from `WEBDYNE_MIME_TYPE_HR` with a plain-text fallback, emits headers, streams the file to the parent response object, and returns an HTTP status code.

# METHODS #

* **run($child_request)**

    Serve the file named by the child request object. Returns `HTTP_NOT_FOUND` if the file does not exist, `HTTP_INTERNAL_SERVER_ERROR` if it cannot be opened, or `HTTP_OK` after streaming the asset.

# NOTES #

Despite the package name, the same helper is also used from fake-request and non-Apache execution paths, so it returns runtime-neutral HTTP status codes.

# AUTHOR #

Andrew Speer <andrew.speer@isolutions.com.au>

# LICENSE and COPYRIGHT

This file is part of WebDyne.

This software is copyright (c) 2026 by Andrew Speer <andrew.speer.com.au>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Full license text is available at:

<http://dev.perl.org/licenses/>


=end markdown


=head1 WebDyne::Request::PSGI::Static


=head1 NAME

WebDyne::Request::PSGI::Static - simple static-file responder for WebDyne PSGI request flows


=head1 SYNOPSIS


 use WebDyne::Request::PSGI::Static;
 
 my $status = WebDyne::Request::PSGI::Static->run($child_request);

=head1 DESCRIPTION

C<WebDyne::Request::PSGI::Static> is a small helper subclass used when a PSGI request should serve a static asset rather than a C<.psp> page.

It reads the nominated file, sets C<Content-Length>, selects a content type from C<WEBDYNE_MIME_TYPE_HR> with a plain-text fallback, emits headers, streams the file to the parent response object, and returns an HTTP status code.


=head1 METHODS

=over

=item *

B<run($child_request)>

Serve the file named by the child request object. Returns C<HTTP_NOT_FOUND> if the file does not exist, C<HTTP_INTERNAL_SERVER_ERROR> if it cannot be opened, or C<HTTP_OK> after streaming the asset.



=back


=head1 NOTES

Despite the package name, the same helper is also used from fake-request and non-Apache execution paths, so it returns runtime-neutral HTTP status codes.


=head1 AUTHOR

Andrew Speer L<mailto:andrew.speer@isolutions.com.au>


=head1 LICENSE and COPYRIGHT

This file is part of WebDyne.

This software is copyright (c) 2026 by Andrew Speer L<mailto:andrew.speer@isolutions.com.au>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Full license text is available at:

L<http://dev.perl.org/licenses/>

=cut
