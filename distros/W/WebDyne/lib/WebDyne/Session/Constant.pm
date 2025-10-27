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


#  Constants
#
package WebDyne::Session::Constant;
use strict qw(vars);
#use vars   qw($VERSION @ISA %EXPORT_TAGS @EXPORT_OK @EXPORT %Constant);
use vars   qw($VERSION @ISA %Constant);
no warnings qw(uninitialized);
local $^W=0;


#  Version information. Must be all on one line
#
$VERSION='2.017';


#  The guts
#
%Constant=(

    #  This is the name of the cookie the browser will receive to keep session id
    #
    WEBDYNE_SESSION_ID_COOKIE_NAME => 'session',


);


#  Export constants to namespace, place in export tags
#
#require Exporter;
require WebDyne::Constant;
#@ISA=qw(Exporter WebDyne::Constant);
@ISA=qw(WebDyne::Constant);
#+__PACKAGE__->local_constant_load(\%Constant);
#foreach (keys %Constant) {${$_}=$Constant{$_}}
#@EXPORT=map {'$' . $_} keys %Constant;
#@EXPORT_OK=@EXPORT;
#%EXPORT_TAGS=(all => [@EXPORT_OK]);
#$_=\%Constant;
