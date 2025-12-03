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
package WebDyne::Err::Constant;


#  Pragma
#
use strict qw(vars);
use vars   qw($VERSION @ISA %Constant);
use warnings;


#  Does the heavy liftying of importing into caller namespace
#
require WebDyne::Constant;
@ISA=qw(WebDyne::Constant);


#  Need the File::Spec module
#
use File::Spec;


#  Version information
#
$VERSION='2.035';


#  Hash of constants
#
%Constant=(


    #  Where we keep the error template
    #
    WEBDYNE_ERR_TEMPLATE => File::Spec->catfile(&class_dn(__PACKAGE__), 'error.psp'),


    #  If set to 1, error messages will be sent as text/plain, not
    #  HTML. If ERROR_EXIT set, child will quit after an error
    #
    WEBDYNE_ERROR_TEXT => 0,
    WEBDYNE_ERROR_EXIT => 0,


);


sub class_dn {


    #  Get class dir
    #
    my $class=shift();


    #  Get package file name so we can look up in inc
    #
    (my $class_fn="${class}.pm")=~s{::}{/}g;
    $class_fn=$INC{$class_fn} ||
        die("unable to find location for $class in \%INC");


    #  Split
    #
    my $class_dn=(File::Spec->splitpath($class_fn))[1];

}


#  Done
#
1;
