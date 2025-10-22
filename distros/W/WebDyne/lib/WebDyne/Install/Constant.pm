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


package WebDyne::Install::Constant;


#  Pragma
#
use strict qw(vars);
use warnings;
no warnings qw(uninitialized);


#  Vars to use
#
#use vars qw($VERSION @ISA %EXPORT_TAGS @EXPORT_OK @EXPORT %Constant);
use vars qw($VERSION @ISA %Constant);


#  External Modules
#
use File::Path;
use File::Spec;


#  Version information
#
$VERSION='2.015';


#------------------------------------------------------------------------------


#  Work out default cache directory location if none spec'd by user and
#  no PREFIX supplied
#
my $cache_default_dn;


#  Windows ?
#
if ($^O=~/MSWin[32|64]/) {
    $cache_default_dn=File::Spec->catdir($ENV{'SYSTEMROOT'}, qw(TEMP webdyne))
}

#  No - set to /var/cache/webdyne
#
else {
    $cache_default_dn=File::Spec->catdir(
        File::Spec->rootdir(), qw(var cache webdyne)
    );
}


#  Real deal
#
%Constant=(


    #  Default cache directory
    #
    DIR_CACHE_DEFAULT => $cache_default_dn


);


sub import {
    
    goto &WebDyne::Constant::import;
    
}


#  Finalise and export vars
#
#require Exporter;
require WebDyne::Constant;
@ISA=qw(Exporter WebDyne::Constant);

#  Local constants override globals
#+__PACKAGE__->local_constant_load(\%Constant);
#foreach (keys %Constant) {${$_}=$Constant{$_}}
#@EXPORT=map {'$' . $_} keys %Constant;
#@EXPORT_OK=@EXPORT;
#%EXPORT_TAGS=(all => [@EXPORT_OK]);
#$_=\%Constant;
