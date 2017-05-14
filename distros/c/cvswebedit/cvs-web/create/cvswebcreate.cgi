#!/usr/local/bin/perl -s
#
# cvswebcreate - a CGI interface to adding and deleting files and directories  
# on the CVS tree.
#
# This script can be used in two ways: as a backend (driven by POST) and as a frontend
# (driven by GET). In either case, the PATH_INFO cgi var sets the directory in which 
# the operation.
#
# If you are POSTing, the parameters (carried after ? on the URL) are:
#	op=add-file, or op=add-directory
#
# This script relies exclusively on 'cvs import' to create empty files and empty directories
# It does not rely on checked out repositories.
# Arguments for 'cvs import' are carried in the post body request. The CGI libraries I
# use merge them into the same namespace as the parameters on the URL.
#	 $req->param("comment");
#	 $req->param("fileordirectoryname");
#	 $req->param("isbinary");
#	 $req->param("vendortag");
#	 $req->param("releasetag");
#	
# CAVEATS:
#
# if they want to add an existing file, then they have to create it 
# and add it separately.
#
# It would be nice to be able to add a set of files.
#
# Can't delete or rename files.

# $Header: /usr/cvs_base/cvs-web/cvswebcreate.pl,v 1.11 1998/02/18 16:43:36 root Exp $
#
# Written by Martin Cleaver <Martin.Cleaver@BCS.org.uk>
#

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
	my $initpathinfo = $ENV{'SCRIPT_FILENAME'}; # was PATH_TRANSLATED b4 Apache.
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

use vars qw($cvswebview_url $cvsroot $cvswebcreate_dbg $cvswebcreate_dbg_mode 
	    $administrator $cvswebcreate_auditlog $cvswebcreate_state);

my $where = $req->cgi->var('PATH_INFO');
$where =~ s|^/||;
$where =~ s|/$||;

require "cvswebconfig.pl";

##### End configuration section


my $fullname = $cvsroot . '/' . $where;

my $scriptname = $req->cgi->var('SCRIPT_NAME');
$scriptname =~ s|^/?|/|;
$scriptname =~ s|/$||;

my $scriptwhere = $scriptname . '/' . $where;
$scriptwhere =~ s|/$||;

#####

AuditLog::init($cvswebcreate_auditlog);

init_output($cvswebcreate_dbg, $cvswebcreate_dbg_mode);
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
#$cvswebcreate_state = 'c:/temp/cvswebcreate';

use File::Path;

sub get_empty_dir {
   my $tempdir = $cvswebcreate_state.'/tempdir';
   unless (-d $cvswebcreate_state and -w _) {
      die "\$cvswebcreate_state ($cvswebcreate_state) must be a directory and writeable -$! ";
   }
   rmtree($tempdir);
   unless (!-f $tempdir) {
      die "cvswebcreate - couldn't clear out temporary directory";
   }
   mkpath($tempdir);
   return $tempdir;
}

# $ cd wdir
# $ cvs import -m "Imported sources" yoyodyne/rdir yoyo start
# The string `yoyo' is a vendor tag, and `start' is a release tag
# $fullname is the path to here.

# To create an empty directory
# cd empty dir.
# cvs import -m "Your explanation here" somelocation/directory vendor release
sub new_directory {
   my $tempdir = get_empty_dir();
   chdir $tempdir or die ("Couldn't cd into $tempdir - $!");
   do_log("In dir $tempdir");
   my $dirname = $req->param("fileordirectoryname");
   $dirname =~ s|/||g; # remove all slashes for security . TODO - audit replacements
   mkdir $dirname, 0755 || die "Couldn't create $dirname - $!";

   #VCS::CVS::radddir, would be nice
   my $cmd = "cvs -d $cvsroot import ";
   $cmd .= ' -m "'.$req->param("comment").'"';
   $cmd .= ' "'.$where.'"';
   $cmd .= ' '.$req->param("vendortag");
   $cmd .= ' '.$req->param("releasetag");
   my $output = log_exec ($cmd." 2>&1");

   output "Content-type: text/html\n\n";
   output "<HTML><HEAD><TITLE>Directory add results</TITLE></HEAD>";
   output "<BODY><H1>Directory add results</H1><HR>".$output."<HR>";
   output "From here, you can <A HREF='$cvswebview_url/$where'>return to listing </A>";
   output "or <A HREF='$scriptwhere'>return to creating new directories</A>";
   output "</HTML></BODY>";

}

#
# To create an empty (possibly binary) file

# -k subst 

# Indicate the RCS keyword expansion mode desired. This setting will
# apply to all files created during the import, but not to any files that
# previously existed in the repository. See section Substitution modes for
# a list of valid `-k' settings.

#-I name 

# Specify file names that should be ignored during import. You can use
# this option repeatedly. To avoid ignoring any files at all (even those
# ignored by default), specify `-I !'. name can be a file name pattern of
# the same type that you can specify in the `.cvsignore' file. See section
# Ignoring files via cvsignore. 

# cd empty dir.
# echo > newfile.txt
# cvs import -I ! [-kb] -m "Your explanation here" somelocation/directory vendor release

sub new_file {
   my $err = undef;
   my $output = undef;
   my $tempdir = get_empty_dir();
   chdir $tempdir or die ("Couldn't cd into $tempdir - $!");
   do_log("In dir $tempdir");
   #VCS::CVS::radd, would be nice
   my $newfilename = $req->param("fileordirectoryname");
   $newfilename =~ s|/||g; # remove all slashes for security 
   # TODO: if this did any replacements, then write the event to an audit log.
   my $fh = new FileHandle(">".$newfilename);
   if ($fh) {
     close $fh;
     my $cmd = "cvs -d $cvsroot import";
     $cmd .= ' -I !';
     $cmd .= ' -kb' if ($req->param("isbinary") eq "yes");
     $cmd .= ' -m "'. # TODO. should store user name!
	"New file added using CVSweb.\n".scalar(gmtime($^T)).
	"\nHOST=".$req->cgi->var('REMOTE_HOST').
	    "\nCOMMENTS={".$req->param('comment')."}\n".'"';
     $cmd .= ' "'.$where.'"'; 
     $cmd .= ' '.$req->param("vendortag");
     $cmd .= ' '.$req->param("releasetag");
     $cmd .= " 2>&1";
     $output = log_exec ($cmd);
   } else {
     $err ="Ugh couldn't create $newfilename in $tempdir - $!";
   }
   output "Content-type: text/html\n\n";
   output "<HTML><HEAD><TITLE>File add results</TITLE></HEAD>";
   output "<BODY><H1>File add results</H1><HR>".$output." ".$err."<HR>";
   output "From here, you can <A HREF='$cvswebview_url/$where'>return to listing </A>";
   output "or <A HREF='$scriptwhere'>Create more files</A>";
   output "</HTML></BODY>";
}

############## Main entry point ##################

if ($req->cgi->var('REQUEST_METHOD') eq 'POST') {
    my $op = $req->param('op');
    if ($op eq "add-file") {
      do_log("new file");
      new_file();
    } elsif ($op eq "add-directory") {
      do_log("new dir");
      new_directory();
    } else {
      not_implemented("The POST create command '$op' was not recognised");
    }
} else {
  show_form();
}

sub show_usage ($$) {
    my ($user, $message) = @_;
    output "Content-type: text/html\n\n";

    output "<H1>Cvswebcreate Usage</H1>";

    output "<H2>$message</H2>\n";
    output "The parameters you supplied to this script are incorrect. ";

    output "Below is a list of possible parameter combinations:\n<P>";
    output "<PRE>";
    output "$scriptname<B>/file/under/CVSROOT</B>?";
    output "op=add-file\n";
    output "op=add-directory\n";
    output "op=delete-file\n";
    output "op=delete-directory\n";

    output "</PRE>\n";
    output "All commands are POST commands\n<P>";
    output "Links to <A HREF='$scriptwhere?edit=show-status'>show-status</A> and <A HREF='$cvswebview_url'>cvsweb</A>\n";
    
    output "<HR>\n";
    return 0;
}


###################### template for form driven interface ###############

sub show_form {

    use CGI::Form;
    my $req = new CGI::Form;
    $req->use_named_parameters(1);

    output "Content-type: text/html\n\n";

    output "You are in directory /$where<P>"; #TODO /?
    output "<H2>What do you want to do?</H2>";


    output $req->start_multipart_form(
	      -action=>"$scriptwhere"
				);

    output $req->popup_menu(-name=>'op',
			    -values=>['add-file','add-directory'],
	                    -default=>'add-file',
			    -label=>"Action",
			);

    output "Name:";
    output $req->textfield(-name=>'fileordirectoryname',
	                    -default=>'New File Name',
	                    -size=>60,
			    -label=>"Name of file or directory in /$where");

    output "<P>";
    output $req->checkbox(-name=>'isbinary',
			    -checked=>'checked', # silly syntax
			    -value=>'yes',
			    -label=>'If this is a file, is it binary?');

    output "<P>Import comment:<BR>\n";
    output $req->textarea(-name=>'comments',
	 		  -default=>'',
	                  -rows=>3,
	                  -columns=>60);


    output $req->textfield(-name=>'vendortag',
	                    -default=>'default-vendor',
	                    -size=>20,
			    -label=>"Vendor tag");

    output $req->textfield(-name=>'releasetag',
	                    -default=>'default-release',
	                    -size=>20,
			    -label=>"Release Tag");

    output '<INPUT type="submit" value="Submit">'."\n";

    output "</BODY></HTML>\n";
    exit 0;
}













