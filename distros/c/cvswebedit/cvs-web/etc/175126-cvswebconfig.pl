# cvswebconfig.pl
# Locations of files 
################# Main Configuration section: ##################
# ------------------ local site  --------------------

# $administrator - the email address of the person responsible for cvsweb at your
# site
#
#$administrator = 'Martin.Cleaver@BCS.org.uk';
$administrator = 'Martin.Cleaver@BCS.org.uk';

# $tempdir - the place where:
#	 1) temporary log files go
#	 2) directories holding the state of the system go
#
#  This directory needs to be writeable by the webserver
#
$tempdir = 'c:/temp/';

# $installdir - the directory containing the read, admin, etc directories as seen by
# command line users.
#
$installdir = 'c:/data/mcleaver/projects/cvswebedit/versions/newrelease-1aug98/cvs-web';

# $installurl - the path on the URL that the $installdir can be seen as by users using 
# the web. This has to match srm.conf (Apache)
$installurl = '/cvs-web';

# This is where the debugging output from cvswebedit is exposed to the web for the admin
# interface. Whatever you write here must match srm.conf
#$cvswebedit_dbg_url = '/cve/'; 
$cvswebedit_dbg_url = '/cve/';


# Set $cvsroot to the root of the CVS tree
# NB. Currently, cvsweb.cgi checks for the existance of this directory
# so you can't have it on a different server.
# NB. on win32 systems you must not have a / on the end of this string.
#     on UNIX systems it shouldn't matter

$cvsroot = "/data/cvsroot";


# ------------------ cvsweb --------------------


#$cvswebview_url = $installurl.'/read/cvsweb.cgi';
$cvswebview_url = $installurl.'/read/cvsweb.cgi';

#$cvswebview_dbg = $tempdir.'/cvswebview.out';
$cvswebview_dbg = $tempdir.'/cvswebview.out';


# ------------------ cvswebedit --------------------

#$cvswebedit_url = $installurl.'/edit/cvswebedit.cgi';
$cvswebedit_url = $installurl.'/edit/cvswebedit.cgi';

#$cvswebedit_state = $tempdir.'/cvsweb_upload/';
$cvswebedit_state = $tempdir.'/cvsweb_upload/';

#$cvswebedit_state_url = ''; # TODO - this should map in srm.conf
$cvswebedit_state_url = '';

#$cvswebedit_dbg = $tempdir.'/cvswebedit.out';
$cvswebedit_dbg = $tempdir.'/cvswebedit.out';

#$cvswebedit_dbg_mode = 'adddate';
$cvswebedit_dbg_mode = '';


# TODO: explain that userdb is only useful if you are not using authentication.
#$cvswebedit_userdb = $installdir.'/etc/userdb.txt';
$cvswebedit_userdb = $installdir.'/etc/userdb.txt';

#$cvswebedit_cookie_name = 'cvswebedit';
$cvswebedit_cookie_name = 'cvswebedit';

#$cvswebedit_auditlog = $tempdir.'/auditlog.txt';
$cvswebedit_auditlog = $tempdir.'/auditlog.txt';

# ------------------ cvswebcreate --------------------

#$cvswebcreate_dbg = $tempdir.'/cvswebcreate.out';
$cvswebcreate_dbg = $tempdir.'/cvswebcreate.out';

#$cvswebcreate_dbg_mode = 'adddate';
$cvswebcreate_dbg_mode = '';

#$cvswebcreate_state = $tempdir.'/cvswebcreate';
$cvswebcreate_state = $tempdir.'/cvswebcreate';

#$cvswebcreate_url = $installurl.'/create/cvswebcreate.cgi';
$cvswebcreate_url = $installurl.'/create/cvswebcreate.cgi';

#$cvswebcreate_auditlog = $tempdir.'/auditlog.txt';
$cvswebcreate_auditlog = $tempdir.'/auditlog.txt';


###########################################################

# ------------------ locations of programs  --------------------
#
# Settings for the META information page
#

$metaprogs{WHAT} = '/usr/ccs/bin/what';
$metaprogs{IDENT} = '/usr/local/bin/ident';
$metaprogs{SORT} = 'sort -u';
$metaprogs{LDD} = 'ldd';
#$metaprogs{FILE} = 'file';

# The cvs and RCS binaries must be in your path.
# 
# Set $rcsbinaries to the location of the RCS binaries, if they're
# not in the web server's $PATH
#$rcsbinaries = '/usr/local/bin';
#if (defined($rcsbinaries)) {
#	$ENV{'PATH'} = $rcsbinaries . ":" . $ENV{'PATH'};
#}

# ------------------ URLS to icons used  --------------------

#
# These icons are all relative to the script running.
#
# $backicon is the icon to be used for the previous directory, if any
$backicon = "/icons/back.gif";

# $diricon is the icon to be used for a directory, if any
$diricon = "/icons/dir.gif";

# $texticon is the icon to be used for a text file, if any
$texticon = "/icons/text.gif";
#

1;

