#!/usr/local/bin/perl -s
#
# cvswebadmin - an admin console to cvswebedit log files
#
# $Header: /usr/cvs_base/cvs-web/cvswebedit.pl,v 1.11 1998/02/18 16:43:36 root Exp $
#
# Written by Martin Cleaver <Martin.Cleaver@BCS.org.uk>
#

use Cwd;
#----------- add the cwd/lib and cwd/etc to @INC. cwd/etc is where config files are.
use Cwd;
BEGIN {
	my $initpathinfo = $ENV{'SCRIPT_FILENAME'}; # PATH_TRANSLATED Apache.
	$initpathinfo =~ s|(.*)/.*$|$1|; # remove name of script
	$initpathinfo =~ s|(.*)/.*$|$1|; # remove /edit directory name
	chdir $initpathinfo;
	push @INC,$initpathinfo.'/lib';
	push @INC,$initpathinfo.'/etc';
	$ENV{'PATH_INFO'} =~ s/$initpathinfo//;
}

print join(" ", @INC), "\n";

use vars qw($cvswebview_url $cvsroot $cvswebedit_dbg $cvswebedit_dbg_url $cvswebedit_cookie_name
	    $cvswebedit_userdb $cvswebedit_state $cvswebedit_state_url $administrator $cvswebedit_auditlog);

require "cvswebconfig.pl";
use strict;
use Cgilog;
use AuditLog;


AuditLog::init($cvswebedit_auditlog);
AuditLog::message("Admin Console started");
AuditLog::close();

print "Content-type: text/html\n\n";
print "<HTML><BODY><h1>Admin Console Output</h1>";
AuditLog::printAsHtml($cvswebedit_auditlog);

print "<HR>\n";

print "<h2>See logs at <A HREF='$cvswebedit_dbg_url'>$cvswebedit_dbg_url</A>\n</H2>";
print "<LI>If this does not work then you need to expose \$cvswebedit_dbg (".$cvswebedit_dbg.") to your webserver as $cvswebedit_dbg_url";

print "<h2>See checkout directories per user at <A HREF='$cvswebedit_dbg_url'>$cvswebedit_dbg_url</A>\n</H2>";
print "<LI>If this does not work then you need to expose \$cvswebedit_state (".$cvswebedit_state.") to your webserver as $cvswebedit_state_url";

print "<LI>You probably want a .htaccess file in your log directory. This should prevent all except admin users seeing the files.";

print "<HR>\n";
print "<FONT SIZE=-2><A HREF='http://www.perl.com/CPAN/modules/by-authors/MRJC/'>CVSwebedit by Martin.Cleaver\@BCS.org.uk</A></FONT>\n";
print "</BODY></HTML>";


