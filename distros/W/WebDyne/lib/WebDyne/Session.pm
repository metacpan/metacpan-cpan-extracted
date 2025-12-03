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
package WebDyne::Session;


#  Compiler Pragma
#
use strict qw(vars);
use vars   qw($VERSION);
use warnings;
no warnings qw(uninitialized);


#  WebDyne Modules.
#
use WebDyne::Session::Constant;
use WebDyne::Util;


#  External modules
#
use Digest::MD5 qw(md5_hex);
use CGI::Simple;


#  Version information
#
$VERSION='2.035';


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
    my $self=$self_cr->()                             || return;

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


    #  Get CGI object ref
    #
    my $cgi_or=$self->CGI() ||
        return err('no CGI object availble');
    


    #  Get cookie name we are looking for
    #
    my $cookie_name=$WEBDYNE_SESSION_ID_COOKIE_NAME;
    
    
    #  Get current value
    #
    my $session_id=$cgi_or->cookie($cookie_name);


    #  Get or set the cookie id
    #
    unless($session_id) {


        #  Debug
        #
        debug('session cookie not found, generating new session_id');


        #  Generate a new session id based on an MD5 checksum
        #
        $session_id=&Digest::MD5::md5_hex(rand($$ . time() . ($self =~ /(\d+)/)[0]));
        debug("generated new session_id $session_id");


        #  If no session id now, something has gone horribly wrong
        #
        $session_id || return $self->err_html(
            'unable to create unique session id'
        );


        #  Debug
        #
        debug("session_id generation success, generated id $session_id");


        #  Create a cookie with our session id
        #
        my $cookie=$cgi_or->cookie(

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

=head1 LICENSE and COPYRIGHT

This file is part of WebDyne.

This software is copyright (c) 2025 by Andrew Speer L<mailto:andrew.speer@isolutions.com.au>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Full license text is available at:

L<http://dev.perl.org/licenses/>

=head1 Author

Andrew Speer, andrew@webdyne.org

=head1 Bugs

Please report any bugs or feature requests to "bug-webdyne-session at
rt.cpan.org", or via
http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WebDyne-Session


