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


#  Constants file  
#
package WebDyne::Filter::Constant;


#  Pragma
#
use strict qw(vars);
use vars   qw($VERSION @ISA %Constant);
use warnings;


#  Does the heavy liftying of importing into caller namespace
#
require WebDyne::Constant;
@ISA=qw(WebDyne::Constant);


#  Version information. Must be all on one line
#
$VERSION='2.060';


#  The guts
#
%Constant=(

    #  This is the name of the cookie the browser will receive to keep session id
    #
    WEBDYNE_FILTER_REQUEST_CR  => undef,
    WEBDYNE_FILTER_RESPONSE_CR => undef


);


#  Done
#
1;
