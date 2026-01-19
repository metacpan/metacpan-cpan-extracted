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


#  Constants
#
package WebDyne::Chain::Constant;


#  Pragma
#
use strict qw(vars);
use vars qw($VERSION @ISA %Constant);
use warnings;


#  Does the heavy liftying of importing into caller namespace
#
require WebDyne::Constant;
@ISA=qw(WebDyne::Constant);


#  Version information. Must be all on one line
#
$VERSION='2.072';


#  Constants are empty, but having this file allows for import of DEBUG and othe
#  vars from /etc/webdyne.conf.pl;
#
%Constant=();


#  Done
#
1;
