#
#
#  Copyright (C) 2006-2010 Andrew Speer <andrew@webdyne.org>. All rights
#  reserved.
#
#  This file is part of WebDyne::Install::Lighttpd.
#
#  WebDyne::Install is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
#
package WebDyne::Install::Lighttpd::Constant;


#  Pragma
#
use strict qw(vars);


#  Vars to use
#
use vars qw($VERSION @ISA %EXPORT_TAGS @EXPORT_OK @EXPORT %Constant);


#  External modules
#
use File::Find;
use File::Spec;


#  Other Constants
#
use WebDyne::Constant;
use WebDyne::Install::Constant;


#  Version information in a format suitable for CPAN etc. Must be
#  all on one line
#
$VERSION='1.002';


#------------------------------------------------------------------------------

#  Name of user httpd runs under
#
my ($lighttpd_uname, $lighttpd_gname, $lighttpd_uid, $lighttpd_gid);
my @lighttpd_uname=$ENV{'LIGHTTPD_UNAME'}
    || qw(lighttpd www-data);
foreach my $name (@lighttpd_uname) {
    unless ($lighttpd_uid || $^O=~/MSWin[32|64]/) {
	if ($lighttpd_uid=getpwnam($name)) { $lighttpd_uname=$name; last }
    }
}
my @lighttpd_gname=$ENV{'LIGHTTPD_GNAME'}
    || qw(lighttpd www-data);
foreach my $name (@lighttpd_gname) {
    unless ($lighttpd_gid || $^O=~/MSWin[32|64]/) {
	if ($lighttpd_gid=getgrnam($name)) { $lighttpd_gname=$name; last }
    }
}


#  Check we have something fo uname etc.
#
unless ($lighttpd_uid ||  $^O=~/MSWin[32|64]/ ) {
    warn('unable to determine lighttpd user name - please supply correct name via LIGHTTPD_UNAME environment variable')};
unless ($lighttpd_gid ||  $^O=~/MSWin[32|64]/ ) {
    warn('unable to determine lighttpd group name - please supply correct name via LIGHTTPD_GNAME environment variable')};



#  Get lighttpd conf file and dir
#
my $lighttpd_conf_fn=&file_lighttpd_conf();
my $lighttpd_conf_dn=(File::Spec->splitpath($lighttpd_conf_fn))[1];


#  Real deal
#
%Constant = (


    #  Config file templates and final names, delimiter if inserted into master httpd.conf
    #
    FILE_WEBDYNE_CONF_TEMPLATE		  =>  'webdyne.conf.inc',
    FILE_WEBDYNE_CONF			  =>  'webdyne.conf',
    FILE_LIGHTTPD_CONF_TEMPLATE		  =>  'lighttpd.conf.inc',
    FILE_LIGHTTPD_CONF_DELIM		  =>  '#== WebDyne '.('=' x 68),


    #  The fastcgi binary
    #
    FILE_FASTCGI_BIN			  =>  'wdfastcgi',
    FILE_FASTCGI_SOCKET			  =>  'wdfastcgi-webdyne.sock',


    #  Get lighttpd directory name
    #
    FILE_LIGHTTPD_CONF			  =>  $lighttpd_conf_fn,
    DIR_LIGHTTPD_CONF			  =>  $lighttpd_conf_dn,


    #  Need lighttpd uid and gid, as some dirs will be chowned to this
    #  at install time
    #
    LIGHTTPD_UNAME			  =>  $lighttpd_uname,
    LIGHTTPD_GNAME			  =>  $lighttpd_gname,
    LIGHTTPD_UID			  =>  $lighttpd_uid,
    LIGHTTPD_GID			  =>  $lighttpd_gid,


   );


#  Get absolute config file location
#
sub file_lighttpd_conf {


    #  If in Win32 need to get location of Apache from reg. Not much error checking
    #  because not fatal if reg key not found etc.
    #
    my $path;
    if ($^O=~/MSWin[32|64]/) {
	$path=
	    # last resorts. blech
	    'C:\Lighttpd;C:\Progra~1\Lighttpd;'.
	    'D:\Lighttpd;D:\Progra~1\Lighttpd;'.
	    'E:\Lighttpd;E:\Progra~1\Lighttpd;';
    }
    else {

    	#  Add some hard coded paths as last resort options.
    	#
	$path='/etc/lighttpd';
    }


    #  Only one name we are looking for .. for now. Put in an arrey for the future
    #
    my @name_conf=qw(lighttpd.conf);


    #  Find the httpd conf file if not spec'd in environment var
    #
    my $httpd_conf;
    unless ($httpd_conf=$ENV{'FILE_LIGHTTPD_CONF'}) {


    	my @dir=grep { -d $_ } split(/:|;/, $path);
	my %dir=map { $_=> 1} @dir;
	DIR: foreach my $dir (@dir) {
	    next unless delete $dir{$dir};
	    next unless -d $dir;
	    foreach my $name_conf (@name_conf) {
		if (-f File::Spec->catfile($dir, $name_conf)) {
		    $httpd_conf=File::Spec->catfile($dir, $name_conf);
		    last DIR;
		}
	    }
	}
    }


    #  Warn if unable to find
    #
    unless (-f $httpd_conf) {
	warn('unable find lighttpd config file location - please supply via FILE_LIGHTTPD_CONF environment var');
    }


    #  Return
    #
    return File::Spec->canonpath($httpd_conf);

}


#  Finalise and export vars
#
require Exporter;
require WebDyne::Constant;
@ISA=qw(Exporter WebDyne::Constant);
#  Local constants override globals
+__PACKAGE__->local_constant_load(\%Constant);
foreach (keys %Constant) { ${$_}=$Constant{$_} }
@EXPORT=map { '$'.$_ } keys %Constant;
@EXPORT_OK=@EXPORT;
%EXPORT_TAGS=(all => [@EXPORT_OK]);
$_=\%Constant;
