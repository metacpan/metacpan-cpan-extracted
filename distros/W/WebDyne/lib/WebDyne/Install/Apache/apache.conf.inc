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
