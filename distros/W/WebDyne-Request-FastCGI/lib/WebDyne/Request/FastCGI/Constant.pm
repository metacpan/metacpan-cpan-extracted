#
#
#  Copyright (C) 2006-2010 Andrew Speer <andrew@webdyne.org>. All rights 
#  reserved.
#
#  This file is part of WebDyne::Request::FastCGI
#
#  WebDyne::Session is free software; you can redistribute it and/or modify
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
package WebDyne::Request::FastCGI::Constant;


#  Pragma
#
use strict qw(vars);
use vars qw($VERSION @ISA %EXPORT_TAGS @EXPORT_OK @EXPORT %Constant);
no warnings qw(uninitialized);
local $^W=0;


#  Version information. Must be all on one line
#
$VERSION='1.002';


#  The guts
#
%Constant = (


    #  A placeholder for per-location WebDyne settings, e.g., WebDyneHandler, etc.
    #
    WEBDYNE_DIR_CONFIG		    =>  undef,


    #  Warn on errors ? Some FastCGI implementations write to error logs (good), others send to client (bad)
    #
    WEBDYNE_FASTCGI_WARN_ON_ERROR   =>  undef,


    #  Max requests on socket if not given see FCGI::OpenSocket
    #
    WEBDYNE_FASTCGI_BACKLOG	    =>  4,


);


#  Export constants to namespace, place in export tags
#
require Exporter;
require WebDyne::Constant;
@ISA=qw(Exporter WebDyne::Constant);
+__PACKAGE__->local_constant_load(\%Constant);
map { ${$_}=$Constant{$_} } keys %Constant;
@EXPORT=map { '$'.$_ } keys %Constant;
@EXPORT_OK=@EXPORT;
%EXPORT_TAGS=(all => [@EXPORT_OK]);
$_=\%Constant;
