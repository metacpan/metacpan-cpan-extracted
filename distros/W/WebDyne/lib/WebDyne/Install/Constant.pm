#
#  This file is part of WebDyne.
#
#  This software is Copyright (c) 2017 by Andrew Speer <andrew@webdyne.org>.
#
#  This is free software, licensed under:
#
#    The GNU General Public License, Version 2, June 1991
#
#  Full license text is available at:
#
#  <http://www.gnu.org/licenses/old-licenses/gpl-2.0.txt>
#

package WebDyne::Install::Constant;


#  Pragma
#
use strict qw(vars);
use warnings;
no warnings qw(uninitialized);


#  Vars to use
#
use vars qw($VERSION @ISA %EXPORT_TAGS @EXPORT_OK @EXPORT %Constant);


#  External Modules
#
use File::Path;
use File::Spec;


#  Version information
#
$VERSION='1.248';


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


    #  Where perl5 library dirs are sourced from
    #
    FILE_PERL5LIB => 'perl5lib.pl',


    #  Default cache directory
    #
    DIR_CACHE_DEFAULT => $cache_default_dn


);


#  Finalise and export vars
#
require Exporter;
require WebDyne::Constant;
@ISA=qw(Exporter WebDyne::Constant);

#  Local constants override globals
+__PACKAGE__->local_constant_load(\%Constant);
foreach (keys %Constant) {${$_}=$Constant{$_}}
@EXPORT=map {'$' . $_} keys %Constant;
@EXPORT_OK=@EXPORT;
%EXPORT_TAGS=(all => [@EXPORT_OK]);
$_=\%Constant;
