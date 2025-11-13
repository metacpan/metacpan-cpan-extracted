#
#  This file is part of WebDyne.
#
#  This software is copyright (c) 2025 by Andrew Speer <andrew.speer@isolutions.com.au>.
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
use HTTP::Status (qw(RC_INTERNAL_SERVER_ERROR RC_NOT_FOUND));
use IO::File;
use WebDyne::Util;
use WebDyne::Constant;


#  Inheritance
#
use WebDyne::Request::PSGI;
@ISA=qw(WebDyne::Request::PSGI);


#  Version information
#
$VERSION='2.028';


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
        return $r->status(RC_NOT_FOUND);
    }
    elsif (my $fh=IO::File->new($fn, O_RDONLY)) {
        my $hr=$r->headers_out();
        my $size=(stat($fn))[7];
        $hr->{'Content-Length'}=$size;
        my $ext=($fn=~/\.(\w+)$/) && $1;
        $hr->{'Content-Type'}=$WEBDYNE_MIME_TYPE_HR->{$ext} || 'text/plain';
        $r->send_http_header();
        while (<$fh>) {$r->print($_)}
        $fh->close();
        return &Apache::OK
    }
    else {
        warn("unable to open file '$fn', $!");
        return $r->status(RC_INTERNAL_SERVER_ERROR);
    }

}
