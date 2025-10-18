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


package WebDyne::Static;


#  Compiler Pragma
#
use strict qw(vars);
use vars   qw($VERSION);
use warnings;
no warnings qw(uninitialized);


#  Utilities, constants
#
use WebDyne::Constant;
use WebDyne::Util;


#  Version information in a format
#
$VERSION='2.014';


#  Debug
#
debug("%s loaded, version $VERSION");


#  And done
#
1;

#------------------------------------------------------------------------------


sub import {


    #  Will only work if called from within a __PERL__ block in WebDyne
    #
    my $self_cr=UNIVERSAL::can(scalar caller, 'self') || return;
    my $self=$self_cr->()                             || return;
    my $meta_hr=$self->meta()                         || return err();
    $meta_hr->{'static'}=1;

}


sub handler : method {


    #  Handler is a no-op, all work is done by filter code. Need a handler so
    #  module is seen by WebDyne autoload method when tracking back through
    #  chained modules
    #
    my $self=shift();
    $self->static(1);
    $self->SUPER::handler(@_);

}
