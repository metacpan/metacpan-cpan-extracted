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


<!-- $OUT=$FILE_APACHE_CONF_DELIM 
-->
#------------------------------------------------------------------------------
#
#  Start of WebDyne section
#
#------------------------------------------------------------------------------
#
#
#  Any modification between the <!-- 


my $delim=$FILE_APACHE_CONF_DELIM;
$delim=~s/^.//;
$OUT=$delim;

--> lines
#  will be lost in the next install/upgrade cycle. 
#
#  Do not edit this section !
#

Include "<!-- $OUT=File::Spec->catfile($DIR_APACHE_CONF,$FILE_WEBDYNE_CONF) -->"


#------------------------------------------------------------------------------
#
#  End of WebDyne section
#
#------------------------------------------------------------------------------
<!-- $OUT=$FILE_APACHE_CONF_DELIM -->
