#
#
#  Copyright (C) 2006-2010 Andrew Speer <andrew@webdyne.org>. All rights
#  reserved.
#
#  This file is part of WebDyne::Request::FastCGI
#
#  WebDyne is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
#
package WebDyne::Request::FastCGI::Static;


#  Compiler Pragma
#
use strict	qw(vars);
use vars	qw($VERSION $AUTOLOAD @ISA);


#  External modules
#
use HTTP::Status (qw(RC_INTERNAL_SERVER_ERROR RC_NOT_FOUND));
use IO::File;
use WebDyne::Base;


#  Inheritance
#
use WebDyne::Request::FastCGI;
@ISA=qw(WebDyne::Request::FastCGI);


#  Version information
#
$VERSION='1.002';


#  Debug load
#
debug("Loading %s version $VERSION", __PACKAGE__);


#  All done. Positive return
#
1;


#==================================================================================================


sub run {

    my ($r, $self)=@_;
    my $fn=$r->filename();
    if (!-f $fn) {
	warn("file '$fn' not found");
	return $r->status(RC_NOT_FOUND);
    }
    elsif (my $fh=IO::File->new($fn, O_RDONLY)) {
	my $hr=$r->headers_out();
	my $size=(stat($fn))[7];
	$hr->{'Content-Length'}=$size;
	$r->send_http_header();
	while (<$fh>) { $r->print($_) }
	$fh->close();
	return &Apache::OK
    }
    else {
	warn("unable to open file '$fn', $!");
	return $r->status(RC_INTERNAL_SERVER_ERROR);
    }

}
