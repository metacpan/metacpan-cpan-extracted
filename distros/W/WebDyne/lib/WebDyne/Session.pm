#
#  This file is part of WebDyne.
#
#  This software is copyright (c) 2026 by Andrew Speer <andrew.speer@isolutions.com.au>.
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
#use Digest::MD5 qw(md5_hex);
use Crypt::URandom qw( urandom );
use CGI::Simple;


#  Version information
#
$VERSION='3.009';


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
    my $class=shift();
    my $self_cr=UNIVERSAL::can(scalar caller, 'self') || return;
    my $self=$self_cr->()                             || return;
    $self->set_handler('WebDyne::Chain');
    my $meta_hr=$self->meta();
    push @{$meta_hr->{'webdynechain'}}, $class;


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
    debug("using cookie_name: $cookie_name");
    
    
    #  Get current value
    #
    my $session_id=$cgi_or->cookie($cookie_name);
    debug("found session_id: $session_id");


    #  Get or set the cookie id
    #
    unless($session_id) {


        #  Debug
        #
        debug('session cookie not found, generating new session_id');


        #  Generate a new session id based on an MD5 checksum. UPDATE deprectaed, CVE-2026-5084 
        #
        #$session_id=&Digest::MD5::md5_hex(rand($$ . time() . ($self =~ /(\d+)/)[0]));
        
        #  Use urandom for session now
        $session_id = unpack("H*", urandom(16));
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

=begin markdown

# WebDyne::Session #

# NAME #

WebDyne::Session - simple session-cookie module for the WebDyne handler chain

# SYNOPSIS #

```perl
__PERL__
use WebDyne::Session;
```

# DESCRIPTION #

`WebDyne::Session` is a chaining module that ensures each request has a session identifier stored in a browser cookie.

When imported from a page `__PERL__` block, it switches the page to `WebDyne::Chain` handling and adds itself to the active chain. At runtime it reads the configured session cookie, generates a new identifier when one is missing, and exposes the identifier through the page object.

# METHODS #

* **handler($self, $r, $param_hr)**

    Read or create the session cookie and then pass control to the next handler in the chain.

* **session_id()**

    Return the current session identifier for the active page/request object.

# CONSTANTS #

Cookie naming is controlled by `WEBDYNE_SESSION_ID_COOKIE_NAME` from `WebDyne::Session::Constant`.

# NOTES #

The current implementation uses `Crypt::URandom` to generate new session IDs.

# AUTHOR #

Andrew Speer <andrew.speer@isolutions.com.au>

# LICENSE and COPYRIGHT

This file is part of WebDyne.

This software is copyright (c) 2026 by Andrew Speer <andrew.speer@isolutions.com.au>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Full license text is available at:

<http://dev.perl.org/licenses/>


=end markdown


=head1 WebDyne::Session


=head1 NAME

WebDyne::Session - simple session-cookie module for the WebDyne handler chain


=head1 SYNOPSIS


 __PERL__
 use WebDyne::Session;

=head1 DESCRIPTION

C<WebDyne::Session> is a chaining module that ensures each request has a session identifier stored in a browser cookie.

When imported from a page C<__PERL__> block, it switches the page to C<WebDyne::Chain> handling and adds itself to the active chain. At runtime it reads the configured session cookie, generates a new identifier when one is missing, and exposes the identifier through the page object.


=head1 METHODS

=over

=item *

B<handler($self, $r, $param_hr)>

Read or create the session cookie and then pass control to the next handler in the chain.



=item *

B<session_id()>

Return the current session identifier for the active page/request object.



=back


=head1 CONSTANTS

Cookie naming is controlled by C<WEBDYNE_SESSION_ID_COOKIE_NAME> from C<WebDyne::Session::Constant>.


=head1 NOTES

The current implementation uses C<Crypt::URandom> to generate new session IDs.


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
