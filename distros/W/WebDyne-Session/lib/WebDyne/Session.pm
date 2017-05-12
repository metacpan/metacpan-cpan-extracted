#
#
#  Copyright (C) 2006-2010 Andrew Speer <andrew@webdyne.org>.
#  All rights reserved.
#
#  This file is part of WebDyne::Session.
#
#  WebDyne::Session is free software; you can redistribute it and/or modify
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
package WebDyne::Session;


#  Compiler Pragma
#
sub BEGIN	{ $^W=0 };
use strict	qw(vars);
use vars	qw($VERSION);
use warnings;
no  warnings	qw(uninitialized);


#  WebDyne Modules.
#

use WebDyne::Session::Constant;
use WebDyne::Base;


#  External modules
#
use Digest::MD5 qw(md5_hex);
use CGI::Cookie;


#  Version information
#
$VERSION='1.044';


#  Shortcut error handler.
#
require WebDyne::Err;
*err_html=\&WebDyne::Err::err_html || *err_html;


#  Debug
#
debug("%s loaded, version $VERSION", __PACKAGE__);


#  And done
#
1;


#------------------------------------------------------------------------------


sub import {


    #  Will only work if called from within a __PERL__ block in WebDyne
    #
    my $self_cr=UNIVERSAL::can(scalar caller, 'self') || return;
    my $self=$self_cr->() || return;
    #$self->set_handler('WebDyne::Session');
    $self->set_handler('WebDyne::Chain');
    my $meta_hr=$self->meta();
    push @{$meta_hr->{'webdynechain'}}, __PACKAGE__;


}


sub handler : method {


    #  Get class, request object
    #
    my ($self, $r, $param_hr)=@_;


    #  Debug
    #
    debug("in %s handler, self $self, r $r, param_hr $param_hr", __PACKAGE__);


    #  Get cookie from header
    #
    my $header_hr=$r->headers_in() ||
	return err('unable to get header hash ref');
    my $cookie=$header_hr->{'cookie'};
    debug("cookie $cookie");


    #  Get cookies hash
    #
    my %cookies=$cookie ? CGI::Cookie->parse($cookie) : ();


    #  Get cookie name we are looking for
    #
    my $cookie_name=$WEBDYNE_SESSION_ID_COOKIE_NAME;


    #  Get or set the cookie id
    #
    my $session_id;
    unless ($session_id=($cookies{$cookie_name} && $cookies{$cookie_name}->value())) {


	#  Debug
	#
	debug('session cookie not found, generating new session_id');


	#  Generate a new session id based on an MD5 checksum
	#
	$session_id=&Digest::MD5::md5_hex(rand($$.time()));
	debug("generated new session_id $session_id");



	#  If no session id now, something has gone horribly wrong
	#
	$session_id || return $self->err_html(
	    'unable to create unique session id');


	#  Debug
	#
	debug("session_id generation success, generated id $session_id");



	#  Create a cookie with out session id
	#
	my $cookie=CGI::Cookie->new(

	    -name  => $cookie_name,
	    -value => $session_id,
	    -path  => '/'

	   ) || return $self->err_html("unable to generate sid: $session_id cookie");


	#  Get our header hash ref
	#
	my $header_hr=$r->headers_out() ||
	    return $self->err_html('unable to get outbound headers');


	#  Reinstall the new cookie into the params that will be passed
	#  to our base header function
	#
	$header_hr->{'Set-cookie'}=$cookie;


    }


    #  Set in class _self area so will be propogated to next blessed self ref
    #
    $self->{'_session_id'}=$session_id;


    #  All done, chain to next handler
    #
    $self->SUPER::handler($r, @_[2..$#_]);


}



sub session_id {


    #  Accessor for session_id var, set in handler above
    #
    my $self=shift();
    return $self->{'_session_id'};


}

__END__

=head1 Name

WebDyne::Session - WebDyne extension module that implements browser sessions

=head1 Description

WebDyne::Session is a WebDyne extension module that implements browser
sessions.  An API provides access to get and set session ID's via browser
cookies.

=head1 Documentation

Information on configuration and usage is availeble from the WebDyne site,
http://webdyne.org/ - or from a snapshot of current documentation in PDF
format available in the WebDyne module source /doc directory.

=head1 Copyright and License

Webdyne::Chain is Copyright (C) 2006-2010 Andrew Speer. WebDyne::Session is
dual licensed.  It is released as free software released under the Gnu
Public License (GPL), but is also available for commercial use under a
proprietary license - please contact the author for further information.

WebDyne::Session is written in Perl and uses modules from CPAN (the
Comprehensive Perl Archive Network).  CPAN modules are Copyright (C) the
owner/author, and are available in source from CPAN directly.  All CPAN
modules used are covered by the Perl Artistic License.

=head1 Author

Andrew Speer, andrew@webdyne.org

=head1 Bugs

Please report any bugs or feature requests to "bug-webdyne-session at
rt.cpan.org", or via
http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WebDyne-Session


