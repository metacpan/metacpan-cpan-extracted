#
#  This file is part of WebDyne.
#
#  This software is Copyright (c) 2016 by Andrew Speer <andrew@webdyne.org>.
#
#  This is free software, licensed under:
#
#    The GNU General Public License, Version 2, June 1991
#
#  Full license text is available at:
#
#  <http://www.gnu.org/licenses/old-licenses/gpl-2.0.txt>
#
package WebDyne::Err::Constant;


#  Pragma
#
use strict qw(vars);
use vars qw($VERSION @ISA %EXPORT_TAGS @EXPORT_OK @EXPORT %Constant);
use warnings;
no warnings qw(uninitialized);
local $^W=0;


#  Need the File::Spec module
#
use File::Spec;


#  Version information
#
$VERSION='1.246';


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
    (my $class_fn="${class}.pm")=~s/::/\//g;
    $class_fn=$INC{$class_fn} ||
        die("unable to find location for $class in \%INC");


    #  Split
    #
    my $class_dn=(File::Spec->splitpath($class_fn))[1];

}


#  Export constants to namespace, place in export tags
#
require Exporter;
require WebDyne::Constant;
@ISA=qw(Exporter WebDyne::Constant);
+__PACKAGE__->local_constant_load(\%Constant);
foreach (keys %Constant) {${$_}=$Constant{$_}}
@EXPORT=map {'$' . $_} keys %Constant;
@EXPORT_OK=@EXPORT;
%EXPORT_TAGS=(all => [@EXPORT_OK]);
$_=\%Constant;
