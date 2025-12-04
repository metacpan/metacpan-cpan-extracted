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



#  Constants file
#
package WebDyne::Install::Constant;


#  Pragma
#
use strict qw(vars);
use vars qw($VERSION @ISA %Constant);
use warnings;


#  Does the heavy liftying of importing into caller namespace
#
require WebDyne::Constant;
@ISA=qw(WebDyne::Constant);


#  External Modules
#
use File::Path;
use File::Spec;


#  Version information
#
$VERSION='2.036';


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


#  Done
#
1;