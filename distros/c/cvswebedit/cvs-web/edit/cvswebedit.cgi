#!/usr/local/bin/perl -s
#
# cvswebedit - a CGI interface to remote editing (reserved checkouts) 
# on the CVS tree.
#
# $Header: /usr/cvs_base/cvs-web/cvswebedit.pl,v 1.11 1998/02/18 16:43:36 root Exp $
#
# Written by Martin Cleaver <Martin.Cleaver@BCS.org.uk>
#
# cvswebedit does cvs 'reserved checkouts' locking using 'cvs admin -l $file'
# this is used only for co-operation with other CVS programs, internally
# it uses a lock directory where the name of the on CVS is used as the lock 
# file. Each lock file contains information about who has checked out the
# file (ie the owner) plus some other details. 
#
# If the file is already checked out when a user tries to edit it, the identity
# of this user is compared with the owner. If the user is not the owner, the
# user is told to talk to the owner.
#
# If the user is the owner then an opportunity to upload the new version is
# presented. The user can also download another copy of the old version or
# can discard the file's lock.
#
# If the user tries to access a non-existant file a list of all files currently
# locked is shown.
#
# This script uses a cookie to remember the username. All user names must be
# listed in the user database.
#
# cvs.texinfo
#
# In some cases unreserved checkouts are clearly inappropriate.  If no
# merge tool exists for the kind of file you are managing (for example
# word processor files or files edited by Computer Aided Design
# programs), and it is not desirable to change to a program which uses a
# mergeable data format, then resolving conflicts is going to be
# unpleasant enough that you generally will be better off to simply
# avoid the conflicts instead, by using reserved checkouts.
#
#
# cvs.man:
#
#`-l[REV]'
#     Lock the revision with number REV.  If a branch is given, lock the
#     latest revision on that branch.  If REV is omitted, lock the
#     latest revision on the default branch.
# 
#     This can be used in conjunction with the `rcslock.pl' script in
#     the `contrib' directory of the CVS source distribution to provide
#     reserved checkouts (where only one user can be editing a given
#     file at a time).  See the comments in that file for details (and
#     see the `README' file in that directory for disclaimers about the
#     unsupported nature of contrib).  According to comments in that
#     file, locking must set to strict (which is the default).
# 
#`-L'
#     Set locking to strict.  Strict locking means that the owner of an
#     RCS file is not exempt from locking for checkin.  For use with
#     CVS, strict locking must be set; see the discussion under the `-l'
#     option above.
#
# rcslock.pl:
# When a developer needs exclusive access to a version of a file, s/he
# should use "rcs -l" in the repository tree to lock the version they
# are working on.  CVS will automagically release the lock when the
# commit is performed.
#
# (cvswebedit does not rely on the automatic unlock in unlock_file, as we 
# also use unlock_file when we do a discard-lock action.

#HTTP_USER_AGENT: Mozilla/1.1N (X11; I; SunOS 4.1.3_U1 sun4m) via proxy gateway CERN-HTTPD/3.0 libwww/2.17
#SERVER_NAME: www.freebsd.org
#QUERY_STRING: baz
#SCRIPT_FILENAME: /usr/local/www/cgi-bin/env.pl
#SERVER_PORT: 80
#HTTP_ACCEPT: */*, image/gif, image/x-xbitmap, image/jpeg
#SERVER_PROTOCOL: HTTP/1.0
#HTTP_COOKIE: s=beta26429821397802167
#PATH_INFO: /foo/bar
#REMOTE_ADDR: 13.1.64.94
#DOCUMENT_ROOT: /usr/local/www/data/
#PATH: /sbin:/bin:/usr/sbin:/usr/bin
#PATH_TRANSLATED: /usr/local/www/data//foo/bar
#GATEWAY_INTERFACE: CGI/1.1
#REQUEST_METHOD: GET
#SCRIPT_NAME: /cgi-bin/env.pl
#SERVER_SOFTWARE: Apache/1.0.0
#REMOTE_HOST: beta.xerox.com
#SERVER_ADMIN: webmaster@freebsd.org

package main;



#----------- add the cwd/lib and cwd/etc to @INC. cwd/etc is where config files are.
use Cwd;
BEGIN {
	my $initpathinfo = $ENV{'SCRIPT_FILENAME'}; # this was PATH_TRANSLATED b4 Apache.
	$initpathinfo =~ s|(.*)/.*$|$1|; # remove name of script
	$initpathinfo =~ s|(.*)/.*$|$1|; # remove /edit directory name
	chdir $initpathinfo;
	push @INC,$initpathinfo.'/lib';
	push @INC,$initpathinfo.'/etc';
	$ENV{'PATH_INFO'} =~ s/$initpathinfo//;
}

use FileHandle;
use File::Path;
use File::Basename;
use CGI::BasePlus;
use CGI::Request;
use CGI::Carp;
use CGI::Cookie;
use strict;
use Cgilog;
use AuditLog;

#CGI::Base::Debug(10);
my $req = new CGI::Request;

use vars qw($cvswebview_url $cvsroot $cvswebedit_dbg $cvswebedit_dbg_mode 
	    $cvswebedit_cookie_name $cvswebedit_userdb $cvswebedit_state 
	    $administrator $cvswebedit_auditlog);


{ # Find config files for this machine.
    local ($^W) = 0;
    use Sys::Hostname;
    my $hostname = hostname();
    $hostname =~ s/([^.*])\..*/$1/;

    die "Can't discover hostname, so can't find config files!" if ($hostname eq "");
    eval {
	require $hostname.'-cvswebconfig.pl'; # Settings per-site
	require $hostname.'-cgi-style.pl';    # Settings for the style of html pages
    } || die "Your machine is '$hostname'. Create config files $hostname-cvswebconfig.pl and $hostname-cgi-style.pl files in \@INC :\n\t $@";
}

##### End configuration section

my $where = $req->cgi->var('PATH_INFO');
$where =~ s|^/||;
$where =~ s|/$||;


my $fullname = $cvsroot . '/' . $where;

my $scriptname = $req->cgi->var('SCRIPT_NAME');
$scriptname =~ s|^/?|/|;
$scriptname =~ s|/$||;

my $scriptwhere = $scriptname . '/' . $where;
$scriptwhere =~ s|/$||;

#####

edit_mkdirs($cvswebedit_state);
AuditLog::init($cvswebedit_auditlog);

init_output($cvswebedit_dbg, $cvswebedit_dbg_mode);
do_log("REQUEST_METHOD=".$req->cgi->var('REQUEST_METHOD')."\n");

my $tmp;
foreach ($req->cgi->vars()) {
    $tmp .= $_.' = '.$req->cgi->var($_)."\n";
}
do_log($tmp);

$tmp = undef;

foreach ($req->params()) {
    $tmp.=$_."=".$req->param($_)."\n";
}
do_log("PARAMS:\n$tmp\n");
####

unless (-d $cvswebedit_state and -w $cvswebedit_state) {
	die ("You must make \$cvswebedit_state ($$cvswebedit_state) writeable. This is used for ".
	     "\n1) the local cvs checkout area and 2) the file ownership area");
}

my %userdb;
eval {
  %userdb = initdb($cvswebedit_userdb);
};  die "Can't open user database '$cvswebedit_userdb' -\n\t This is a colon separated file, username:Full name\n - \n$@" if ($@);

my %cookies = CGI::Cookie->fetch();
my $user = get_user($req, %cookies);

do_log("USER=$user\n");
unless ($user) {		# allow user to select username only if get_user failed.
    login_user();
}


my $cookie = CGI::Cookie->new(-name=>$cvswebedit_cookie_name, 
			      -path=>$scriptname,
			      -value=>$user)->as_string();
output "Set-Cookie: ". $cookie."\n";

if (!defined($userdb{$user})) {
    output "Content-type: text/html\n\n";
    
    output "<HTML><HEAD><title>Invalid user id</title></HEAD>";
    output "<BODY><H1>Your user id ($user) is not recognised</H1>\n";
    output "Please contact $administrator";
    output '</BODY></HTML>';
    exit 0;
}

do_log("U=$user\nF=$where\nC=$fullname\n");

if ($req->cgi->var('REQUEST_METHOD') eq 'POST') {
    my $edit = $req->param('edit');
    if ($edit eq 'upload-and-unlock') {
	upload_and_unlock($user, $where, 'HEAD');
    } elsif($edit eq 'submit-text-changes') {
	submit_text_changes($user, $where, 'HEAD');	
    } else {
	not_implemented("The POST edit command '$edit' was not recognised");
    }
} else {
    handle_path($user);
}


#if the web server sets the username, don't override it.
sub get_user ($%) {
    my ($req, %cookies) = @_;
    my $user = $req->cgi->var('REMOTE_USER');    
    unless ($user) {$user = $req->param('user')};
    unless ($user) {
	if ($cookies{$cvswebedit_cookie_name}) {
	    $user = $cookies{$cvswebedit_cookie_name}->value();
	}
    }
    return $user;
}


sub login_user {
    use CGI::Form;
    my $query = new CGI::Form;

    $query->use_named_parameters(1);

    output "Content-type: text/html\r\n\r\n";
    output $query->start_html(-title=>'Please log in',
			     -author=>$administrator,
			     );

    output $query->startform(-method=>'GET', 
			     -action=>$scriptwhere."?");

    my @userids = keys %userdb;

    output $query->popup_menu(-name=>'user',
			      -values=>\@userids,
			      -default=>'',
			      -labels=>\%userdb);

    output $query->submit(-name=>'edit',
			  -value=>'start',
			  -label=>'Go');

    output "\n<P>";

    output "Return to viewing <A HREF='$cvswebview_url'>repository<A>\n";

    output $query->end_html();

    do_log($query->dump());

    output $query->endform;
    output "<HR>\n";

    exit 0;
}


sub initdb ($){
    my ($dbfile) = @_;
    my %db;
    my $fh = new FileHandle($dbfile) || die $!;

    my $line;
    while($line = <$fh>) {
	my ($user, $name) = split /:/, $line;
	$db{$user} = $name;
#	do_log($db{$user}."=".$user."\n");
    }
    if (%db == undef) {
	die "File empty or no newline at end of file";
    }
    return %db;
}

sub show_usage ($$) {
    my ($user, $message) = @_;
    show_edit_header($user, "", ""); # FIXME

    output "<H1>Cvswebedit Usage</H1>";

    output "<H2>$message</H2>\n";
    output "The parameters you supplied to this script are incorrect. ";

    output "Click here if you wish to <A HREF='$scriptwhere?edit=start'>start editing $where</A>\n<P> ";

    output "Below is a list of possible parameter combinations:\n<P>";
    output "<PRE>";
    output "$scriptname<B>/file/under/CVSROOT</B>?";
# You can get a rough and ready list of these by grepping for '$script'
    output "edit=start\n";
    output "edit=lock-and-download\n";
    output "edit=download-file\n";
    output "edit=discard-lock\n";
    output "edit=break-lock (not yet implemented)\n";
    output "edit=upload-form\n";
    output "edit=upload-and-unlock [POST]\n";
    output "edit=submit-text-changes [POST]\n";
    output "edit=show-status\n";
    output "edit=show-usage\n";
    output "</PRE>\n";
    output "commands are GET commands unless specified eg. [POST]\n<P>";
    output "Links to <A HREF='$scriptwhere?edit=show-status'>show-status</A> and <A HREF='$cvswebview_url'>cvsweb</A>\n";
    
    output "<HR>\n";

    show_edit_footer($user, "", ""); # FIXME
    return 0;
}

sub handle_path ($) {
    my ($user) = @_;
    my ($newname, $newplace, @files, $xtra, $module);
    my $rev = $req->param('rev');
    my $edit = $req->param('edit');

    do_log("edit=$edit\n");
    if ($edit eq 'show-status') {
	show_status($user, "");
	exit 0;
    } elsif ($edit eq 'show-usage') {
	show_usage($user, "");
	exit 0;
    }

    if (-d $fullname) {
	show_usage($user,"Cvswebedit can not do operations on directories");
        exit 0;
    } elsif (-f $fullname . ',v') {
	if ($req->param('edit')) {
	    show_file_for_edits($where,
				$rev,
				$user);
	} else {
	    # go back to cvsweb
	    show_usage($user, "");
	}
    } else {
	do_log("No such file $fullname");
	show_usage($user, "Path '$where' not recognised on server");
    }
}

{ # variable scope.
    my @files_found;
    my $lockdir;

    sub show_status ($$) {
	my ($user, $message) = @_;
	my %user2files;
#	$user2files{'test'} = ('my file1', 'my file2');
	# Hash indexed by user name pointing to an array of paths.
	# $user2files{user1} = (/path1/file1, /path2/file2, ...);
	# $user2files{user2} = (/path3/file3);
	
	my %file2user; 
	# Hash indexed by path pointing to a user name.
	# $file2user{/path1/file1} = "user1"
	# $file2user{/path2/file2} = "user1"
	# $file2user{/path3/file3} = "user2"
	
	show_edit_header($user, "", ""); # FIXME
#	output "Content-type: text/html\n\n";
	output "<H1>User and File Status</H1>\n";
#status for $userdb{$user} ($user)
	output "<H2>$message</H2>";
	
	use File::Find;

	$lockdir = lock_dir();
	chdir $lockdir;
	find(\&user_files, ".");

	my @allfiles = @files_found;
	output "<pre>";
	
	do_log("lock files found: @allfiles");
	do_log(join(",", @allfiles));
	
	my $lockfile;
	my %filedetails;
	
	foreach $lockfile (@allfiles) {
	    do_log "$lockfile:\n";
	    %filedetails = checkout_hash($lockfile);
	    my $key;
	    foreach $key (keys %filedetails) {
		do_log "$key=$filedetails{$key}\n";
	    }
	    
	    my $file = $filedetails{FILE};
	    my $user = $filedetails{USER};
	    
	    push @{$user2files{$user}}, $file;
	    $file2user{$file} = $user;	
	}

	output "\n<HR><h2>Users owning file:</h2>\n";
	
	my @files;
	my $rauser;
	output "<UL>\n";
	# for each user in the user list, show what files he has
	foreach $rauser (keys %user2files) { # reference to arrays of users.
	    my @files = @{$user2files{$rauser}};
	    output "<LI>User=$rauser, files: ";
	    my $file;
	    foreach $file (@files) {
		output "<A HREF='$scriptname/$file?edit=start&user=$user'>$file</A>, ";
	    }
	}
	output "</UL>";
	output "<HR><h2>Files belonging to users:</h2>\n";	
	output "<UL>\n";
# for each file, there is exactly one user
	my $file;
	foreach $file (keys %file2user) { 
	    my $owner = $file2user{$file};
	    output "<LI>File = <A HREF='$scriptname/$file?edit=start&user=$user'>$file</A> (owned by $owner)\n";
	}
	output "</UL>";	

	show_edit_footer($user, "", "");
    }

    sub user_files {
        my ($file) = $File::Find::name;
	my $lockfile = $lockdir."/".$file;
        do_log("Looking at $file");

# FIXME: consider how to resync lock database with repository. 
# Perhaps a separate command edit=resync-database?
#
#	if (! -f $cvsroot."/".$file.",v") {
#	    do_log("Oh, lock files out of sync with repository");
#	}

	push (@files_found, $file) if (-f $lockfile);
    }
} # variable scope

{ # variable scope
    my $cvswebstatedir = undef;
    my $co_dir;
    my $file2users;

sub edit_mkdirs ($) {
    my ($c) = @_;
    $cvswebstatedir = $c;
    $co_dir = $cvswebstatedir.'/users-checkout';
    $file2users = $cvswebstatedir.'/file-to-users';

    mkpath $co_dir || carp $!;
    mkpath $file2users || carp $!;
}

sub checkout_dir {
    my ($user) = @_;
    my $dir = $co_dir.'/'.$user;
    do_log ("CO DIR = $dir\n");
    mkpath $dir unless -d $dir;
    return $dir;
}


# Note the user is not factored into the lock directory name.
sub lock_dir {
    my $dir = $file2users;
    do_log ("LOCK DIR = $dir\n");
    mkpath $dir unless -d $dir;
    return $dir;
}

sub checkout_hash {
    my ($lockfile) = @_;
    my ($line, $key, $value);
    if (($lockfile eq "") or (!defined($lockfile))) {
	carp "lockfile name was null!";
	exit 1;
    };

    do_log("opening checkout_hash for $lockfile ...");
    my $fh = new FileHandle ($lockfile) || return {}; 
    my %attributes;
    while($line = <$fh>) {
	do_log($line);
	chomp($line);
	($key,$value) = split('=', $line);
	$attributes{$key}=$value;
    }
    close $fh;
    return %attributes;
}


sub checkout_details ($$) {
    my ($file, $rev) = @_;
    do_log("checkout_details FILE=$file, REV=$rev\n");
    my $lockfile = lock_dir().'/'.$file;    
    if (!-f $lockfile) {
	return "No current file";
    }
#FIXME: use checkout_hash
    my $ans = "<PRE>\n".log_exec("cat $lockfile")."</PRE>"; 
    return $ans;
}

# This should be integrated or replaced with the CVS notion of locking.
# (rcslock.pl)
sub lock_file {
    my ($user, $file, $rev) = @_;
    do_log("lock_file USER=$user, FILE=$file, REV=$rev\n");

    unless ($rev) {
	# FIXME: is this logic right?
	my $res = admin_lock($file, $user);
	$res =~ m/(.*) locked/;
	$rev = $1;
	do_log("REV is now $rev\n");
    }

    update_lockfile($user, $file, $rev);
}

sub update_lockfile($$$) {
    my ($user, $file, $rev) = @_;
    my $lockfile = lock_dir().'/'.$file;
    mkpath dirname($lockfile);
    do_log("lockfile = $lockfile\n");

    my $fh = new FileHandle ($lockfile, "w") || carp $!; #FIXME
    print $fh "USER=$user\n";
    print $fh "FILE=$file\n";
    print $fh "REV=$rev\n";
    print $fh "DATE=".scalar(gmtime)."\n";
    close $fh;
}



# FIXME user name shouldn't be passed in.
sub who_owns_file {
    my ($user, $file, $rev) = @_;
    my $lockfile = lock_dir().'/'.$file;
    my %attributes = checkout_hash($lockfile);

    do_log("does user $user own file $file (what is in $lockfile)?");

    if (!exists($attributes{USER})) {
	do_log("$file not checked out");
	return undef;
    } else {
	do_log("Someone has checked this file out");
    }

    
    return $attributes{USER};
}

sub unlock_file {
    my ($user, $file, $rev) = @_;
    do_log("unlock_file USER=$user, FILE=$file, REV=$rev\n");
    my $lockfile = lock_dir().'/'.$file;

    my $owner = who_owns_file($user,$file,$rev);
    do_log("OWNER=$owner\n");
    if ($owner eq $user) {

	# FIXME - should use release, but can't release a single file in
	# a directory.
	log_chdir checkout_dir($user) || carp $!; # FIXME
#	log_system("rm -f $file");
#	do_log("Checked out copy removed");

	log_system("rm -f $lockfile");
	do_log("Lock file removed");

    } else {
	do_log("You ($user) are not the owner of file ($file), owner is ($owner)");
    }
    if (-f $lockfile) {
	output "ERROR - Lock file not deleted!";
    }

#    if (-f $file) {
#	output "ERROR - CVS file not deleted!";
#    }

    admin_unlock($file, $user);

}

} # variable scope



sub lockowner_returning {
    my ($user, $file, $rev) = @_;

    output "<H2>You ($user) have file $file checked out. </H2>";
    output "What do you want to do?";
    output "<OL><LI><A HREF='$scriptwhere?edit=upload-form&user=$user'>upload your changes as a new version</A>\n";
    output "<LI><A HREF='$scriptwhere?edit=discard-lock&user=$user'>discard lock</A>\n";
    output "<LI><A HREF='$scriptwhere?edit=download-file&file=$file&user=$user'>Download again the CVS copy of $file</A>\n";
    output "<LI><A HREF='$cvswebview_url/$where'>See this file in Cvsweb</A>\n";
    output "</OL>\n";

}

sub not_implemented (;$) {
    my ($message) = @_;
    show_usage($user, "Not Implemented - $message");

}

sub discard_lock {
    my ($user, $file, $rev) = @_;

    show_edit_header($user, $file, $rev);
    
    unlock_file($user, $file, $rev);
    if (defined(who_owns_file($user, $file, $rev))) {
	output "Oops. This shouldn't happen. \n"; #FIXME
	output checkout_details($file, $rev);
    } else  {
	output "File unlocked\n<P>";
    }

    show_edit_footer($user, $file, $rev);
}

sub show_edit_header {
    my ($user, $file, $rev) = @_;
    # FIXME: rev=$rev
    
    output "Content-type: text/html\n\n";
    output "<HTML><HEAD><TITLE>Edit $file</TITLE></HEAD>\n";
    output "<BODY>"; 


    output '<TABLE BGCOLOR="#ff99cc" WIDTH="600" '.
	'CELLSPACING="0" CELLPADDING="6" BORDER="1">';
    output '<TR>';

    output "<H2>Edit $file</h2>\n";

    output '<TR>';
    my %topbarpairs = ($cvswebview_url => 'Cvsweb top',
		       $cvswebview_url.'/'.$where => "Cvs log",
		       $scriptwhere.'?edit=upload-form' => "Upload",
		       $scriptwhere.'?edit=text' => "Edit in browser",
		       $scriptwhere.'?edit=discard-lock' => "Discard lock",
		       $scriptwhere.'?edit=download-file' => "Download",
		       $scriptwhere.'?edit=show-status' => "CvswebEdit status",
		       );
    my $key;
    foreach $key (sort keys %topbarpairs) { # FIXME: want to dictate order
	output '<TD VALIGN="top" ALIGN="CENTER">'; # | ';
	output '<A HREF="'.$key.'">';
	output '<FONT COLOR="#002200" FACE="arial" SIZE="2">';
	output '<STRONG>'.$topbarpairs{$key}."</STRONG></A></FONT></TD>\n";
    }
    
    output "</TR></TABLE><P>\n";

    output "\n";

}


sub show_edit_footer {
    my ($user, $file, $rev) = @_;

    output "<HR>\n";
    output "<h3>Current file ($file) status</h3>\n";

    output checkout_details($file, $rev);
    output "<HR>\n";
    
    output "Your CVS Web administrator is $administrator<P>\n";
    output "<FONT SIZE=-2><A HREF='http://www.perl.com/CPAN/modules/by-authors/MRJC/'>CVSwebedit by Martin.Cleaver\@BCS.org.uk</A></FONT>\n";
    output "</BODY></HTML>\n";
}


sub show_file_for_edits ($$$) {
    my ($file, $rev, $user) = @_;
    my $edit = $req->param("edit");
    
    do_log("show_file_for_edits: USER=$user, EDIT=$edit, FILE=$file, REV=$rev\n");

# FIXME: verify user != ""

    if ($edit eq "start") {
	show_edit_header($user, $file, $rev);
	show_file_for_edit_binary($user, $file, $rev);
	show_edit_footer($user, $file, $rev);
	return;
    }

    #FIXME: new feature. Not yet tested.
    if ($edit eq "text") {
	show_file_for_edit_text($user, $file, $rev);
    }

    # lockowner

    if ($edit eq "lock-and-download") {
        lock_and_download($user, $file, $rev);
	return;	
    }

    if ($edit eq "download-file") {
	download_checked_out_file($user, $file, $rev);
	return;
    }

    # other users

    if ($edit eq "break-lock") {
	not_implemented("Break lock is not yet implemented");
    }

    # lock owner.
    if ($edit eq "upload-form") {
	upload_form($user, $file, $rev);
	return;
    }

    if ($edit eq "discard-lock") {
	discard_lock($user, $file, $rev);
	return;
    }

    if ($edit eq "show-status") {
	show_status($user, "Status of files in repository");
        return;
    }

    not_implemented("The GET edit command '$edit' was not recognised");

}

# FIXME: package VCS::CVS or similar.   Need to think about this.

sub admin_lock ($$) {
    my ($file, $user) = @_;
    log_chdir checkout_dir($user) || carp $!; # FIXME
    # <PROBLEM> how are we going to fake the username doing the checkout?
    #  POSSIBLE SOLUTION: use chat2 or the new Expect module. Consider whether want to 
    #  grab passwords over the net or whether the chat server should run as root.
    # </PROBLEM>
    AuditLog::message("$user LOCK $file"); 
    return log_exec ("cvs -d $cvsroot admin -l $file 2>&1");
}

sub admin_unlock ($$) {
    my ($file, $user) = @_;
    log_chdir checkout_dir($user) || carp $!; # FIXME
    # PROBLEM: how are we going to fake the username doing the checkout?
    AuditLog::message("$user UNLOCK $file");
    return log_exec ("cvs -d $cvsroot admin -u $file 2>&1");
}


sub checkout ($$) {
    my ($file, $user) = @_;
    log_chdir checkout_dir($user) || carp $!; # FIXME
    # PROBLEM: how are we going to fake the username doing the checkout?
    AuditLog::message("$user CHECKOUT $file");
    my $output = log_exec ("cvs -d $cvsroot co $file 2>&1");

    return $output;
}

sub checkin ($$$) {
    my ($file, $user, $message) = @_;
    log_chdir checkout_dir($user) || carp $!; # FIXME
    # FIXME maybe cvs commit -F- and read from file containing log message.
    # FIXME: rev number in log should be updated.
    AuditLog::message("$user CHECKIN $file");
    my $output = log_exec("cvs -d $cvsroot commit -m'$message' $file 2>&1");
    $output =~ s/\n/ /g;

    if ($output eq '') {
	# FIXME: there must be a better way. 
	# Should get 'cvs.bin commit: Examining rweb-docs' ?
	
	do_log("output was blank ?? does this mean the user commited the same version?\n");

	return "Output was blank - perhaps you commited a file identical to the one already in CVS?\n";
    }
    
    if ($output =~ m/Checking in (.*); .* new revision: (.*); previous revision: (.*) done /) {
	my $newfile = $1;
	my $newrev = $2;
	my $prevrev = $3;

	do_log("Checkin new version NEWFILE=$newfile, NEWREV=$newrev, PREVREV=$prevrev\n");
	
# FIXME
#	if ($prevrev ne $rev) {
#          do_log("ERROR: old cvsweb revision ($rev) is not the same as old cvs revision ($prevrev)\n");
#        }
	
	if ($newfile ne $file) {
	    do_log("ERROR: old cvsweb filename ($file) is not the same as old cvs revision ($newfile)\n");
	}

	update_lockfile($user, $file, $newrev);

    } else {
	do_log("Can't change lock stats, didn't match, output was $output");
    }
    return $output;
}

### end of package VCS::CVS or whatever


sub lock_and_download {
    my ($user, $file, $rev)  = @_;
    show_edit_header($user, $file, $rev);
    lock_file($user, $file, $rev);
    checkout($file, $user);

    output ("<H2> Please download the file you have checked out</H2>");
    output ("<A HREF=\"$scriptwhere?edit=download-file&file=$file&user=$user\">$file</A>");

    show_edit_footer($user, $file, $rev);
}

sub buffer_copy {
    my ($infh, $outfh) = @_;
    my ($total, $buf_length, $buffer, $cycles) = (0, 0, 0, 0);
    no strict 'refs';

    while ($buf_length = sysread ($infh, $buffer, 16384))
    {
	# Syswrite can get interrupted, so we may need to do several.
	my $offset = 0;
	while ($offset < $buf_length)
	{
	    my $written = syswrite ($outfh, $buffer, $buf_length, $offset);
	    # FIXME - remove die_page
	    die_page("Write error on file: $!") unless $written;
	    $offset += $written;
	}
	$total += $buf_length;
	if (++$cycles >= 50) {
	    $cycles = 0;
	    do_log("Still copying to file after 50 chunks...\n");
	}
    }
    return $total;
}

sub download_checked_out_file {
    my ($user, $file, $rev)  = @_;

    output "Content-type: Application/octet-stream\n\n";
    flush STDOUT; # EXTBUG - without this the Content-type is sent after the
                  # file
    log_chdir checkout_dir($user) || carp $!; # FIXME
    if (! -f $file) {
	do_log("$file not found"); #FIXME
    }
    my $fh = new FileHandle $file, "r" || carp $!; # FIXME
    binmode($fh);
    buffer_copy($fh, \*STDOUT);
    close $fh;
}


sub upload_form {
    my ($user, $file, $rev)  = @_;
#    show_edit_header($user, $file, $rev);

    use CGI::Form;
    my $query = new CGI::Form;

    $query->use_named_parameters(1);

    show_edit_header($user, $file, $rev);

    output "<H1>Upload Changes to $where</H1>\n";
#FIXME: should specify the file type. 

#EXTBUG: filetype default is HTML
#EXTBUG: I say multipart I get url-encoded!
#    output $query->start_multipart_form(-action=>"$scriptwhere?edit=upload-and-unlock&user=$user", -enctype=>$CGI::MULTIPART);

    output '<FORM METHOD="POST"'.
	" ENCTYPE=\"multipart/form-data\" ".
	    "ACTION=\"$scriptwhere\">";


    output '<TABLE width=600 COLSPEC="L20 L80" cellpadding=5>'."\n";

    output '<TR><TH width="60" align="left"><TH width="60" align="left"></tr>'."\n";

    output '<TR><TD>File: </TD><TD>';

    output $query->filefield(-name=>'uploadfile',
			     -default=>$file,
	                     -size=>66);
    output '</TD></TR>'."\n";

    output "Change comments go here:<P>\n";
    output $query->textarea(-name=>'comments',
			    -default=>'',
			    -rows=>5,
			    -columns=>80);

    output $query->checkbox(-name=>'unlock',
			    -checked=>'checked', # silly syntax
			    -value=>'yes',
			    -label=>'unlock this file once uploaded');


    output '<TR><TD colspan="2" align="right">'."\n".
	'<INPUT type="submit" value="Submit"></TD></TR>'."\n";

    output "</TABLE>\n";

    # For some weird reason, we can't pass name=value pairs and expect
    # them to end up in QUERY_STRING. Instead they have to go in the form..
    $query->param('edit', 'upload-and-unlock');
    output $query->hidden(-name=>"edit");

    # stupid. We have to modify the parameter so that it changes for next time.

    show_edit_footer($user, $file, $rev);
}


sub save_upload {
    my ($user, $file, $rev, $infh) = @_;

    my $outfh = new FileHandle "$file.new", "w" or
	die_page("Cannot write $file.new: $!");
    
    do_page("Starting to save buffer");
    my $total = buffer_copy($infh, $outfh);
    do_page("Done saving buffer");

    {no strict 'refs';
     close $infh;
     close $outfh;
    }

    rename ("$file.new", $file) or
	die_page("Cannot rename $file.new: $!");
    return $total;
}

{ # variable scope
#FIXME: this boundary scope is ugly.
    my $boundary;
    BEGIN {
	$boundary = '---===oooOOOooo===---';
    }


sub do_page
{
    # this sends the next multipart page with the text sent as a parameter
    my ($text_to_print) = @_;
    output "$boundary\r\n",
        "Content-type: text/html\r\n\r\n";
    # the /n above are required,  but below they're just there to help reading
    output "<HTML>\n<HEAD>\n<TITLE>Upload Progress</TITLE>\n",
        "</HEAD>\n<BODY>\n<h2>CVSWEB Upload</h2>\n",
        "$text_to_print<p>\n",
        "</BODY>\n</HTML>\n";

    sleep 1;
}


sub upload_and_unlock {
    my ($user, $file, $rev)  = @_;
    output "Content-type: multipart/mixed;boundary=$boundary\r\n\r\n";

# FIXME: verify user != ""

    if (who_owns_file($user, $file, $rev) ne $user) {
	do_page("You are not the file owner!");
# FIXME: verify user is owner!

# FIXME: check valid html on exiting..

	return 1;

    } 

    upload_file($user, $file, $rev);

    if ($req->param("unlock") eq "yes") {
	unlock_file($user, $file, $rev);
    } else {
	do_log("user said don't unlock");
    }

    my $message =
	"Checkin by $user using CVSweb.\n".scalar(gmtime($^T)).
	    "\nHOST=".$req->cgi->var('REMOTE_HOST').
		"\nEDIT=In-Browser".
		    "\nLOCALFILE=".$req->param('uploadfile').
			"\nCOMMENTS={".$req->param('comments')."}\n";

    my $commit_status = checkin($file, $user, $message);
 
    output "$boundary\r\n";
    show_edit_header($user, $file, $rev);
    output "<h2>Upload result:</h2>$commit_status\n";
    show_edit_footer($user, $file, $rev);
    
}

sub upload_file {
    my ($user, $file, $rev)  = @_;
    my $uploadfile;

    $| = 1; # unbuffer the output
    if (defined $req->param and ($req->param('uploadfile') =~ m:^(.+)$:))    {
# NB pathname could contain spaces!
	# untaint the uploadfile-name
	$uploadfile = $1;
	do_log("Upload file parameter is $uploadfile");
    } else {
	do_log("No upload file parameter");
	$uploadfile = "";
	return; # FIXME
    }

    my $uploadfh = $uploadfile; # CGI.pm aliases filename to the filehandle.

    do_page("Server is saving your upload<BR>");
    log_chdir checkout_dir($user) || carp $!; # FIXME

    my $filesize = save_upload($user, $file, $rev, $uploadfh);
    do_page("File copied to dropzone.<br>\n".
	"Done - written $filesize bytes to file $file<br>\n".
	    "Time: ". scalar(gmtime). "<p>\n");

}

sub die_page
{   # this replaces a real die.  It returns a page and then dies.
    my ($die_text,$code) = @_;
    my $text_line = "<h3>Internal error</h3>\n".
                 "Please try again, and if the error re-occurs, ".
                 "please contact $administrator.\n".
                 "<!-- Sorry -->\n";
    do_page($text_line);
    carp $die_text;
}   # end die_page


sub show_file_for_edit_text {
    my ($user, $file, $rev) = @_;
    lock_file($user, $file, $rev);
    checkout($file, $user);

    # slurp whole file
    my $fh = new FileHandle(checkout_dir($user)."/".$file) || carp $!; #FIXME
    my $filecontents = join("", <$fh>); 
    close $fh;

    use CGI::Form;
    my $req = new CGI::Form;
    $req->use_named_parameters(1);
    show_edit_header($user, $file, $rev);

    output "<H2>Edit Text File</H2>";

    output "You have now got $file locked. Please make your changes and hit submit.<P>";
    output "Use 'discard lock' to abandon changes if you want to not make alterations to this file";

    output $req->start_multipart_form(
	      -action=>"$scriptwhere"
				);

    output $req->textarea(-name=>'filecontents',
	 		  -default=>$filecontents,
	                  -rows=>20,
	                  -columns=>60);

    output "<P>Change comments go here:<P>\n";
    output $req->textarea(-name=>'comments',
	 		  -default=>'',
	                  -rows=>5,
	                  -columns=>80);

    output $req->checkbox(-name=>'unlock',
			    -checked=>'checked', # silly syntax
			    -value=>'yes',
			    -label=>'unlock this file once uploaded');

    output '<INPUT type="submit" value="Submit">'."\n";


    # For some weird reason, we can't pass name=value pairs and expect
    # them to end up in QUERY_STRING. Instead they have to go in the form..
    $req->param('edit', 'submit-text-changes');
    output $req->hidden(-name=>"edit");

    # stupid. We have to modify the parameter so that it changes for next time.

    show_edit_footer($user, $file, $rev);
    exit 0;
}

# FIXME: merge back into upload_and_unlock
sub submit_text_changes {
    my ($user, $file, $rev) = @_;

    output "Content-type: multipart/mixed;boundary=$boundary\r\n\r\n";

# FIXME: verify user != ""

    if (who_owns_file($user, $file, $rev) ne $user) {
	do_page("You are not the file owner!");
# FIXME: verify user is owner!

# FIXME: check valid html on exiting..

	return 1;

    } 

    my $newfilecontents = $req->param('filecontents');
    my $fh = new FileHandle(checkout_dir($user)."/".$file, "w") || carp $!; #FIXME
    print $fh $newfilecontents;
    close $fh;


    if ($req->param("unlock") eq "yes") {
	unlock_file($user, $file, $rev);
    } else {
	do_log("user said don't unlock");
    }

    my $message =
	"Checkin by $user using CVSweb.\n".scalar(gmtime($^T)).
	"\nHOST=".$req->cgi->var('REMOTE_HOST').
	    "\nEDIT=In-Browser".
	    "\nCOMMENTS={".$req->param('comments')."}\n";

    my $commit_status = checkin($file, $user, $message);
 
    output "$boundary\r\n";
    show_edit_header($user, $file, $rev);
    output "<h2>Upload result:</h2>$commit_status\n";
    show_edit_footer($user, $file, $rev);
    
}


sub show_file_for_edit_binary {
    my ($user, $file, $rev) = @_;

    my $owner = who_owns_file($user, $file, $rev);
    do_log("OWNER=$owner\n");

    if ($owner eq $user) {
	lockowner_returning($user, $file, $rev);
	return;
    } elsif (defined($owner)) {
	# someone_else_has_file_out
	output "<H2> This file is checked out by $owner</H2>";
	output "The system shows $file is checked out: <BR>\n";
	output "<PRE>\n".checkout_details($file, $rev)."\n</PRE>";
	output "Please talk to this user if you need to edit this file\n";
	# output "Alternatively you can break this users' lock";
	# output '<A HREF="$scriptwhere/$file?edit=break-lock&user=$user">'.
	   'break the lock</A> button<BR>\n';
	return;
    }

    output "<H2> You ($user) can lock and download to edit this file. </H2>\n";
    output "If you wish to edit this file, please hit the".
	"<A HREF='$scriptwhere?edit=lock-and-download&user=$user'>".
	    " lock and download</A> button<BR>\n";
    return;
}


} # variable scope













