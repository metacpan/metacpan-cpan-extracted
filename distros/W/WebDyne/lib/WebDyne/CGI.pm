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
package WebDyne::CGI;


#  Pragma
#
use strict qw(vars);
use vars   qw($VERSION $AUTOLOAD);
use warnings;
no warnings qw(uninitialized redefine);


#  WebDyne Modules
#
use WebDyne::Util;


#  External modules
#
use Data::Dumper;


#  Version information
#
$VERSION='2.071';


#  Debug load
#
debug("Loading %s version $VERSION", __PACKAGE__);


#==============================================================================

sub new {

    
    #  Need to work out if supplying Plack::Request or CGI::Simple object
    #
    my ($class, $r, %param)=@_;
    debug("class: $class, r:$r, caller: %s", Dumper([caller(0)]));
    
    
    #  Request handler ?
    #
    if (ref($r) eq 'WebDyne::Request::PSGI') {
    
        # Plack
        #
        debug('detected Plack request handler');
        require WebDyne::CGI::PSGI;
        *new=WebDyne::CGI::PSGI::new;
 
        
    }
    elsif (ref($r)=~/^Apache2(?:::Request)?/) {
    
        #  Apache 2
        #
        debug('detected Apache MP2 request handler');
        require WebDyne::CGI::Simple;
        *new=WebDyne::CGI::Simple::new;


    }
    elsif (ref($r)=~/^Apache(?:::Request)?$/) {
    
        # Ugh. Apache 1
        #
        debug('detected Apache MP1 request handler');
        require WebDyne::CGI::Simple;
        *new=WebDyne::CGI::Simple::new;
        

    }
    else {
    
        #  Command line or everything else is CGI::Simple;
        #
        debug('defaulting to CGI::Simple handler, r:%s', Dumper($r));
        require WebDyne::CGI::Simple;
        
        #  Note closure - we *don't* want to pass $r or param to CGI::Simple if 
        #  not in mod_perl
        *new=sub { &WebDyne::CGI::Simple::new() };
        
    }
    

    #  Done
    #
    return $class->new($r, %param);
    
}

1;

