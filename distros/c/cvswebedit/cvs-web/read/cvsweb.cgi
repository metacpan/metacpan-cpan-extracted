#!/usr/local/bin/perl -s
#
# cvsweb - a CGI interface to the CVS tree.
#
# Note, this is under RCS control in /home/fenner:
# $Header: /usr/cvs_base/cvs-web/cvsweb.pl,v 1.12 1998/02/18 17:16:53 root Exp $
#
# Written by Bill Fenner <fenner@freebsd.org>.
# Some modifications by Martin Cleaver <Martin.Cleaver@BCS.org.uk>
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

# Known deficiencies:
#   Moved page redirecting to cvswebedit.pl doesn't work
#              [LOW - user should never see the page]


package main;
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


use FileHandle;
use File::Path;
use CGI::Base;
use CGI::Request;
use strict;
use Cgilog;

require 'timelocal.pl';
require 'ctime.pl';

#
# $req - CGI request object.
#

my $req = new CGI::Request;

##########################
#
# Configuration Settings.
#   Global variables for package main
#   These are those that are defined in etc/$hostname-cvswebconfig.pl

use vars qw($title $h1 $intro $shortinstr $ignore $v);
use vars qw($cvsroot $rcsbinaries $backicon $diricon $texticon $tailhtml);
use vars qw(%metaprogs $cvstree $cvstreedefault $cvswebedit_url $cvswebcreate_url);
use vars qw($cvswebview_dbg);

require "cvswebconfig.pl";

init_output($cvswebview_dbg);
do_log("test");

###############################################
#
# Global variables for package main
#

my $cvswebversion = '$Revision: 1.12 $ MC';
my $updir;      # Last directory we were in.
my $verbose = $v;

my $where = $req->cgi->var('PATH_INFO');
$where =~ s|^/||;
$where =~ s|/$||;

my $fullname = $cvsroot . '/' . $where;

my $scriptname = $req->cgi->var('SCRIPT_NAME');
$scriptname =~ s|^/?|/|;
$scriptname =~ s|/$||;

my $scriptwhere = $scriptname . '/' . $where;
$scriptwhere =~ s|/$||;

my $querystring =  $req->cgi->var('QUERY_STRING');
my $query = '?'.$querystring; #FIXME - check correct

###############################################

if (!-d $cvsroot) {
    fatal("500 Internal Error",'cvsroot \''.$cvsroot.'\' not found!');
}

###############################################

do_log("FULLNAME=$fullname\nSCRIPTWHERE=$scriptwhere\nQUERYSTRING=$querystring");

handle_path();
exit 0;

###############################################

sub handle_path {
    my ($newname, $newplace, @files, $xtra, $module);
    if (-d $fullname) {
	display_directory($fullname);
	exit 0;
    } elsif (-f $fullname . ',v') {
	display_file($fullname);
	exit 0;
    } elsif ($fullname =~ s/\.diff$// && -f $fullname . ",v" &&
	     $req->param('r1') && $req->param('r2')) {
	
	# Allow diffs using the ".diff" extension
	# so that browsers that default to the URL
	# for a save filename don't save diff's as
	# e.g. foo.c
	
	# Note diffs are normally handled in display_file();
	display_diff_between_revisions($fullname);
	exit;
    } elsif (($newname = $fullname) =~ s|/([^/]+)$|/Attic/$1| &&
	     -f $newname . ",v") {
	# The file has been removed and is in the Attic.
	# Send a redirect pointing to the file in the Attic.
	($newplace = $scriptwhere) =~ s|/([^/]+)$|/Attic/$1|;
	redirect($newplace);
	exit;
    } elsif (0 && (@files = safeglob($fullname . ",v"))) {
	output "Content-type: text/plain\n\n";
	output "You matched the following files:\n";
	output join("\n", @files);
	# Find the tags from each file
	# Display a form offering diffs between said tags
    } else {
	# Assume it's a module name with a potential path following it.
	$xtra = $& if (($module = $where) =~ s|/.*||);
	# Is there an indexed version of modules?
	if (open(MODULES, "$cvsroot/CVSROOT/modules")) {
	    while (<MODULES>) {
		if (/^(\S+)\s+(\S+)/o && $module eq $1
		    && -d "${cvsroot}/$2" && $module ne $2) {
		    redirect($scriptname . '/' . $2 . $xtra);
		}
	    }
	}
	do_log("Nothing matched");
	fatal("404 Not Found","Handling path '$where': didn't exist - no such file or directory");
    }
}

sub htmlify {
	my ($string) = @_;

	$string =~ s/&/&amp;/g;
	$string =~ s/</&lt;/g;
	$string =~ s/>/&gt;/g;

	# MC? - what does this do?
#        if ($pr) {
#                $string =~ s|\bpr(\W+[a-z]+/\W*)(\d+)|<A HREF=/cgi/query-pr.cgi?pr=$2>$&</A>|ig;
#        }
 
	return $string;
}

sub htlink {
	my ($name, $where) = @_;
	return "<A HREF=\"$where\">$name</A>\n";
}

sub revcmp {
	my ($rev1, $rev2) = @_;
	my (@r1) = split(/\./, $rev1);
	my (@r2) = split(/\./, $rev2);
	local ($a,$b);

	while (($a = shift(@r1)) && ($b = shift(@r2))) {
	    if ($a != $b) {
		return $a <=> $b;
	    }
	}
	if (@r1) { return 1; }
	if (@r2) { return -1; }
	return 0;
}

sub fatal {
	my ($errcode, $errmsg) = @_;
	output "Status: $errcode\n";
	output html_header("Error");
#	output "Content-type: text/html\n"; #DELME
#	output "\n";
#	output "<HTML><HEAD><TITLE>Error</TITLE></HEAD>\n";
#	output "<BODY>Error: $errmsg</BODY></HTML>\n";
	output "Cvsweb Error: $errmsg\n";
	output html_footer();
	exit(1);
}

sub redirect {
        my($url) = @_;
        output "Status: 301 Moved\n";
        output "Location: $url\n";
        output html_header("Moved");
#       output "Content-type: text/html\n"; #DELME
#       output "\n";
#       output "<HTML><HEAD><TITLE>Moved</TITLE></HEAD>\n";
#       output "<BODY>This document is located <A HREF=$url>here</A>.</BODY></HTML>\n";
        output "This document is located <A HREF=$url>here</A>.\n";
        output html_footer();
        exit(1);
}
 
sub safeglob {
        my($filename) = @_;
        my($dirname);
        my(@results);
 
        ($dirname = $filename) =~ s|/[^/]+$||;
        $filename =~ s|.*/||;

	my ($glob, $t);
        if (opendir(DIR, $dirname)) {
                $glob = $filename;
        #       transform filename from glob to regex.  Deal with:
        #       [, {, ?, * as glob chars
        #       make sure to escape all other regex chars
                $glob =~ s/([\.\(\)\|\+])/\\$1/g;
                $glob =~ s/\*/.*/g;
                $glob =~ s/\?/./g;
                $glob =~ s/{([^}]+)}/($t = $1) =~ s-,-|-g; "($t)"/eg;
                foreach (readdir(DIR)) {
                        if (/^${glob}$/) {
                                push(@results, $dirname . "/" .$_);
                        }
                }
        }
 
        @results;
}


sub display_file {
    do_log("FULLNAME=$fullname\n");
# Okay, the file exists...
    
    my $method = $ENV{'REQUEST_METHOD'};
    do_log("METHOD=".$method."\n");
    
    if ($method eq 'POST') {
	upload_and_unlock('TEST', $where, 'REV'); # FIXME
    }

    do_log($req->param());
    if ($req->param()) {
	if ($req->param('meta')) {
	    display_meta($fullname, $req->param('rev'));
	    exit 0;
	}
	
	if ($req->param('rev')) {
	    display_single_revision($fullname);
	    exit 0;
	}
	
	if ($req->param('r1')) {
	    display_diff_between_revisions($fullname);
	    exit 0;
	}
		    
    } else {
	do_log("No parameters, showing log");
	display_log($fullname);
    }
}

sub display_directory {
        opendir(DIR, $fullname) || fatal("404 Not Found","couldn't find directory to display '$where': $!");
        my @dir = readdir(DIR);
        closedir(DIR);
        if ($where eq '') {
            output html_header($h1); #FIXME bad name
            output $intro;
        } else {
            output html_header("/$where");
            output $shortinstr;
        }
        output "<p>Current directory: <b>/$where</b>\n";
        output "<HR NOSHADE>\n";
	output "<A HREF='$cvswebcreate_url/$where?op=add-file'>Create file</A>&nbsp;";
	output "<A HREF='$cvswebcreate_url/$where?op=add-directory'>Create dir</A>";
        output "<HR NOSHADE>\n";

        # Using <MENU> in this manner violates the HTML2.0 spec but
        # provides the results that I want in most browsers.  Another
        # case of layout spooging up HTML.
        output "<MENU>\n";

	my ($i, $haveattic);
        lookingforattic:
        for ($i = 0; $i <= $#dir; $i++) {
                if ($dir[$i] eq "Attic") {
                        last lookingforattic;
		    }
	    }
	$haveattic = 1 if ($i <= $#dir);
	if (!$req->param("showattic") && ($i <= $#dir) &&
	    opendir(DIR, $fullname . "/Attic")) {
	    splice(@dir, $i, 1,
		   grep((s|^|Attic/|,!m|/\.|), readdir(DIR)));
	    closedir(DIR);
	}

	my ($c, $d, $attic);
        # Sort without the Attic/ pathname.
        foreach (sort {($c=$a)=~s|.*/||;($d=$b)=~s|.*/||;($c cmp $d)} @dir) {
            if ($_ eq '.') {
                next;
            }
            if (s|^Attic/||) {
                $attic = " (in the Attic)";
            } else {
                $attic = "";
            }
            if ($_ eq '..') {
                next if ($where eq '');
                ($updir = $scriptwhere) =~ s|[^/]+$||;
                output "<IMG SRC=\"$backicon\"> ",
                    htlink("Previous Directory",$updir . $query), "<BR>";
#               output "<IMG SRC=???> ",
#                   htlink("Directory-wide diffs", $scriptwhere . '/*'), "<BR>";
            } elsif (-d $fullname . "/" . $_) {
                output "<IMG SRC=\"$diricon\"> ",
                    htlink($_ . "/", $scriptwhere . '/' . $_ . '/' . $query),
                            $attic, "<BR>";
            } elsif (s/,v$//) {

#FIXME: $query?
#FIXME: icons? binary files?

# TODO: add date/time?  How about sorting?
		my $file_attic = ($attic ? "Attic/" : "").$_; 
                output "<IMG SRC=\"$texticon\"> ";
                output " ". htlink($_, $scriptwhere.'/'.$file_attic, $_). " ";
                output " ".htlink("(text)", $scriptwhere.'/'.$file_attic.'?rev=HEAD&content-type=text/plain');
		output " ".htlink("(edit)","$cvswebedit_url/$where/$file_attic?edit=start");
                output '<BR>';
            }
        }

	my $k;
        output "</MENU>\n";
        if ($req->param("only_on_branch")) {
            output "<HR><FORM METHOD=\"GET\" ACTION=\"${scriptwhere}\">\n";
            output "Currently showing only branch $req->param('only_on_branch').\n";
            $req->param("only_on_branch");
            foreach $k ($req->param()) { #FIXME check
                output "<INPUT TYPE=hidden NAME=$k VALUE=$req->param($k)>\n" if $req->param($k);
            }
            output "<INPUT TYPE=SUBMIT VALUE=\"Show all branches\">\n";
            output "</FORM>\n";
        }
        my $formwhere = $scriptwhere;
        $formwhere =~ s|Attic/?$|| if ($req->param("showattic"));
        if ($haveattic) {
                output "<HR><FORM METHOD=\"GET\" ACTION=\"${formwhere}\">\n";
                $req->param("showattic", !$req->param("showattic"));
                foreach $k ($req->param()) {
                    output "<INPUT TYPE=hidden NAME=$k VALUE=".$req->param($k).">\n" if $req->param($k);
                }
                output "<INPUT TYPE=SUBMIT VALUE=\"";
                output ($req->param("showattic") ? "Show" : "Hide");
                output " attic directories\">\n";
                output "</FORM>\n";
        }
        output html_footer();
        output "</BODY></HTML>\n";

}

sub display_single_revision ($) {
        my ($fullname) = @_;
	my $rev = $req->param('rev');

#	output ">$rev\n";

	my $fh = get_rev($fullname, $rev);
	$| = 1;
	if ($req->param('content-type')) {
            output "Content-type: ".$req->param('content-type')."\n";
	} 
	if ($req->param('content-encoding')) {
	    if ($req->param('content-encoding') eq "x-gzip" ) {
               output "Content-encoding: x-gzip\n\n";
	       open(GZIP, "|gzip -1 -c");	# need lightweight compression
	       print GZIP <$fh>;
	       close(GZIP);
	    }
	} else {
	    output "\n";
	    output <$fh>;
	}
	close($fh);
}

sub get_rev {
    my ($fullname, $rev) = @_;

# /home/ncvs/src/sys/netinet/igmp.c,v  -->  standard output
# revision 1.1.1.2
# /*

    if ($rev eq "HEAD") {
	$rev = "";
    }

    my $fh = new FileHandle("co -p$rev '$fullname' 2>&1 |") ||
	fail("500 Internal Error", "Couldn't co: $!");
# /home/ncvs/src/sys/netinet/igmp.c,v  -->  standard output
# revision 1.1.1.2
# /*
    $_ = <$fh>;
    if (/^(\S+),v\s+-->\s+st(andar)?d ?out(put)?\s*$/o && $1 eq $fullname) {
	# As expected

    } else {
	fatal("500 Internal Error",
	      "Unexpected output from co: $_ ".
	      "(Filename requested wasn't in output)");
    }
    $_ = <$fh>;
    
    if ($_ =~ /^revision\s+$rev\s.*$/) {
	# As expected
    } else {
	unless ($rev eq "") {
	    fatal("500 Internal Error",
	      "Unexpected output from co: $_ ".
	      "(Revision number requested wasn't in output)");
	}
    }
    return $fh
}

sub cvsroot {
    return '' if $cvstree eq $cvstreedefault;
    return "&cvsroot=" . $cvstree;
}

sub display_meta {
    my ($fullname, $rev) = @_;
     
    $| = 1;

    output "Content-type: text/html\n";
    output "\n";
    
    output "<HTML><HEAD><TITLE>Meta information for $fullname rev=$rev</TITLE></HEAD>";
    output "<BODY><H1>Meta information for $fullname rev=$rev</H1>\n";
    output "<HR>\n";

# FIXME: Think of extra meta information (Filesize, cvs rstatus, etc)

# darn, file on solaris can't work on a file on standard input.
$ignore = <<'EOM'; 
    my $fh = get_rev($fullname, $rev);
    output "\nFile information:\n";
    output "<PRE>";
    open (FILECMD, "|$metaprogs{FILE}");
    print FILECMD <$fh>;
    close FILECMD;
    output "</PRE>";
EOM

    my $fh = get_rev($fullname, $rev);
    output "\nCVS/RCS information:\n";
    output "<PRE>";
    open (IDENT, "|$metaprogs{IDENT}");
    print IDENT <$fh>;
    close IDENT;
    output "</PRE>";
    
    $fh = get_rev($fullname, $rev);
    output "SCCS information:\n";
    output "<PRE>";
    open (WHAT, "|$metaprogs{WHAT} | $metaprogs{SORT}");
    print WHAT <$fh>;
    close WHAT;
    output "</PRE>";

    $fh = get_rev($fullname, $rev);
    output "LDD information:\n";
    output "<PRE>";
    open (LDD, "|$metaprogs{LDD}");
    print LDD <$fh>;
    close LDD;
    output "</PRE>";

    output "<HR>\n";
    close $fh;
}  

sub display_diff_between_revisions {
    my ($qs) = @_;

    my $r1 = $req->param('r1');
    my $r2 = $req->param('r2');
    my $tr1 = $req->param('tr1');
    my $tr2 = $req->param('tr2');

    my ($rev1, $rev2);
    my ($sym1, $sym2);
    my ($tmp1, $tmp2);
    my ($diffname, $difftype);
    my ($f1, $f2);

    if ($r1 =~ /([^:]+)(:(.+))?/) {
	$rev1 = $1;
	$sym1 = $3;
    }
    if ($rev1 eq 'text') {
	$rev1 = $tr1;
    }
    if ($r2 =~ /([^:]+)(:(.+))?/) {
	$rev2 = $1;
	$sym2 = $3;
    }
    if ($rev2 eq 'text') {
	$rev2 = $tr2;
    }

    do_log "REV1=$rev1, REV2=$rev2\n";

    if (!($rev1 =~ /^[\d\.]+$/) || !($rev2 =~ /^[\d\.]+$/)) {
	fatal("404 Not Found",
	       "Malformed query \"$ENV{'QUERY_STRING'}\"");
    }
#
# rev1 and rev2 are now both numeric revisions.
# Thus we do a DWIM here and swap them if rev1 is after rev2.
# XXX should we warn about the fact that we do this?
   if (revcmp($rev1,$rev2) > 0) {
	($tmp1, $tmp2) = ($rev1, $sym1);
	($rev1, $sym1) = ($rev2, $sym2);
	($rev2, $sym2) = ($tmp1, $tmp2);
    }

    my %diffsets = ("c" => ["Context Diff", '-p -c'],
		    "s" => ["Side by Side", '--side-by-side --width=164'],
		    "u" => ["Unified Diff", '-p -u']);
    $difftype = "c";
    if ($req->param('f')) {
	$difftype = $req->param('f');
    }

    $diffname = $diffsets{$difftype}[0];
    my $diffopts = $diffsets{$difftype}[1];

    do_log("DIFFTYPE = $difftype, DIFFNAME= $diffname, DIFFOPTS= $diffopts\n");

# XXX should this just be text/plain
# or should it have an HTML header and then a <pre>
    output "Content-type: text/plain\n\n";
    my $cmd = "rcsdiff $diffopts -r$rev1 -r$rev2 '$fullname' 2>&1 |";
    do_log($cmd);
    open(RCSDIFF, $cmd) ||
		fail("500 Internal Error", "$cmd - Couldn't rcsdiff: $!");
#
#===================================================================
#RCS file: /home/ncvs/src/sys/netinet/tcp_output.c,v
#retrieving revision 1.16
#retrieving revision 1.17
#diff -c -r1.16 -r1.17
#*** /home/ncvs/src/sys/netinet/tcp_output.c     1995/11/03 22:08:08     1.16
#--- /home/ncvs/src/sys/netinet/tcp_output.c     1995/12/05 17:46:35     1.17
#
# Ideas:
# - nuke the stderr output if it's what we expect it to be
# - Add "no differences found" if the diff command supplied no output.
#
#*** src/sys/netinet/tcp_output.c     1995/11/03 22:08:08     1.16
#--- src/sys/netinet/tcp_output.c     1995/12/05 17:46:35     1.17 RELENG_2_1_0
# (bogus example, but...)
#
	    if ($difftype eq '-u') {
		$f1 = '---';
		$f2 = '\+\+\+';
	    } else {
		$f1 = '\*\*\*';
		$f2 = '---';
	    }
	    while (<RCSDIFF>) {
		if (m|^$f1 $cvsroot|o) {
		    s|$cvsroot/||o;
		    if ($sym1) {
			chop;
			$_ .= " " . $sym1 . "\n";
		    }
		} elsif (m|^$f2 $cvsroot|o) {
		    s|$cvsroot/||o;
		    if ($sym2) {
			chop;
			$_ .= " " . $sym2 . "\n";
		    }
		}
		output $_;
	    }
	    close(RCSDIFF);

}


sub display_log {
        my ($fullname) = @_;

	local($^W) = 0;
	my %revsym;
	my %log;
	my $curbranch;
	my $symnames;
	my %date;
	my @revorder;
	my %symrev;
	my %author;
	my %state;
	my $sel;
	my $headrev;
	my @branchnames;
	my %branchpoint;

	my $onlyonbranch; #FIXME - where does this get set?

	
	open(RCS, "rlog '$fullname'|") || fatal("500 Internal Error",
						"Failed to spawn rlog");
	while (<RCS>) {
	    output if ($verbose);
            if (/^branch:\s+([\d\.]+)/) {
                $curbranch = $1;
            }

	    if ($symnames) {
		if (/^\s+([^:]+):\s+([\d\.]+)/) { 
		    $symrev{$1} = $2;
		    if ($revsym{$2}) {
			$revsym{$2} .= ", ";
		    }
		    $revsym{$2} .= $1;
		} else {
		    $symnames = 0;
		}
	    } elsif (/^symbolic names/) {
		$symnames = 1;
	    } elsif (/^-----/) {
		last;
	    }
	}
# each log entry is of the form:
# ----------------------------
# revision 3.7.1.1
# date: 1995/11/29 22:15:52;  author: fenner;  state: Exp;  lines: +5 -3
# log info
# ----------------------------
	my $yr;
	my $rev;
	logentry:
	while (!/^=========/) {
	    $_ = <RCS>;
            last logentry if (!defined($_));    # EOF
	    output "R:", $_ if ($verbose);
	    if (/^revision ([\d\.]+)/) {
		$rev = $1;
	    } elsif (/^========/ || /^----------------------------$/) {
		next logentry;
	    } else {
                # The rlog output is syntactically ambiguous.  We must
                # have guessed wrong about where the end of the last log
                # message was.
                # Since this is likely to happen when people put rlog output
                # in their commit messages, don't even bother keeping
                # these lines since we don't know what revision they go with
                # any more.
                next logentry;
#		fatal("500 Internal Error","Error parsing RCS output: $_");
	    }
	    $_ = <RCS>;
	    output "D:", $_ if ($verbose);
	    if (m|^date:\s+(\d+)/(\d+)/(\d+)\s+(\d+):(\d+):(\d+);\s+author:\s+(\S+);|) {
		$yr = $1;
		# damn 2-digit year routines
		if ($yr > 100) {
		    $yr -= 1900;
		}
		$date{$rev} = timelocal($6,$5,$4,$3,$2 - 1,$yr);
		$author{$rev} = $7;
                $state{$rev} = $8;

	    } else {
		fatal("500 Internal Error", "Error parsing RCS output: $_");
	    }
	    line:
	    while (<RCS>) {
		output "L:", $_ if ($verbose);
		next line if (/^branches:\s/);
		last line if (/^----------------------------$/ || /^=========/);
		$log{$rev} .= $_;
	    }
	    output "E:", $_ if ($verbose);
	}
	close(RCS);
	output "Done reading RCS file\n" if ($verbose);
#
# Sort the revisions into commit-date order.
	@revorder = sort {$date{$b} <=> $date{$a}} keys %date;
	output "Done sorting revisions\n" if ($verbose);
#
# HEAD is an artificial tag which is simply the highest tag number on the main
# branch, unless there is a branch tag in the RCS file in which case it's the
# highest revision on that branch.  Find it by looking through @revorder; it
# is the first commit listed on the appropriate branch.
        $headrev = $curbranch || "1";
	my $i;
	revision:
        for ($i = 0; $i <= $#revorder; $i++) {
            if ($revorder[$i] =~ /^(\S*)\.\d+$/ && $headrev eq $1) {
                if ($revsym{$revorder[$i]}) {
                    $revsym{$revorder[$i]} .= ", ";
                }
                $revsym{$revorder[$i]} .= "HEAD";
                $symrev{"HEAD"} = $revorder[$i];
                last revision;
            }
        }
	output "Done finding HEAD\n" if ($verbose);
#
# Now that we know all of the revision numbers, we can associate
# absolute revision numbers with all of the symbolic names, and
# pass them to the form so that the same association doesn't have
# to be built then.
#
# should make this a case-insensitive sort
	my ($head, $branch, $regex);
	foreach (sort keys %symrev) {
	    $rev = $symrev{$_};
	    if ($rev =~ /^(\d+(\.\d+)+)\.0\.(\d+)$/) {
                push(@branchnames, $_);
		#
		# A revision number of A.B.0.D really translates into
		# "the highest current revision on branch A.B.D".
		#
		# If there is no branch A.B.D, then it translates into
		# the head A.B .

		$head = $1;
		$branch = $3;
		$regex = $head . "." . $branch;
		$regex =~ s/\./\./g;
		#             <
		#           \____/
		$rev = $head;
		
		revision:
		my $r;
		my $rev;
		foreach $r (@revorder) {
		    if ($r =~ /^${regex}/) {
			$rev = $head . "." . $branch;
			last revision;
		    }
		}
		$revsym{$rev} .= ", " if ($revsym{$rev});
		$revsym{$rev} .= $_;
                if ($rev ne $head) {
                    $branchpoint{$head} .= ", " if ($branchpoint{$head});
                    $branchpoint{$head} .= $_;
                }
	    }
	    $sel .= "<OPTION VALUE=\"${rev}:${_}\">$_\n";
	}
	output "Done associating revisions with branches\n" if ($verbose);
        output html_header("CVS log for $where");

        my $upwhere;

        ($upwhere = $where) =~ s|(Attic/)?[^/]+$||;
        output "Up to ", htlink($upwhere,$scriptname . "/" . $upwhere . $query);
        output "<BR>\n";
        output "<A HREF=\"#diff\">Request diff between arbitrary revisions</A>\n";
        output "<HR NOSHADE>\n";
        if ($curbranch) {
            output "Default branch is ";
            output ($revsym{$curbranch} || $curbranch);
        } else {
            output "No default branch";
        }
        output "<BR><HR NOSHADE>\n";

# The other possible U.I. I can see is to have each revision be hot
# and have the first one you click do ?r1=foo
# and since there's no r2 it keeps going & the next one you click
# adds ?r2=foo and performs the query.
# I suppose there's no reason we can't try both and see which one
# people prefer...

my @prevrev;
my $br;
my $prev;
my ($tmp1, $tmp2);
my (@tmp1, @tmp2);
my $sym;
my %nameprinted;
my %branchpoint; #FIXME - is this in the right place?
my $onlybranchpoint; #FIXME - where does this get set?

       for ($i = 0; $i <= $#revorder; $i++) {
	    $_ = $revorder[$i];
            ($br = $_) =~ s/\.\d+$//;
            next if ($onlyonbranch && $br ne $onlyonbranch &&
                                            $_ ne $onlybranchpoint);
            output "<a NAME=\"rev$_\"></a>";
            foreach $sym (split(", ", $revsym{$_})) {
                output "<a NAME=\"$sym\"></a>";
            }
            if ($revsym{$br} && !$nameprinted{$br}) {
                foreach $sym (split(", ", $revsym{$br})) {
                    output "<a NAME=\"$sym\"></a>";
                }
                $nameprinted{$br}++;
            }
            output "\n";

	    output "<b>$_</b>";
	    output "<A HREF=\"$scriptwhere?rev=$_\">auto</A>, ";
	    output "<A HREF=\"$scriptwhere?rev=$_&content-type=text/plain\">text</A>, ";
	    output "<A HREF=\"$scriptwhere?rev=$_&content-type=application/octet-stream\">binary</A> ";


	    if (/^1\.1\.1\.\d+$/) {
		output " <i>(vendor branch)</i>";
	    }
	    output " <i>" . ctime($date{$_}) . " UTC</i> by ";
	    output "<i>" . $author{$_} . "</i>\n";
	    output " <A HREF=\"$scriptwhere?rev=$_&meta=1\"><b>meta info</b></A>";
	    output " <A HREF=\"$cvswebedit_url/$where?edit=start\"><b>cvsweb edit</b></A>";

	    if ($revsym{$_}) {
		output "<BR>CVS Tags: <b>$revsym{$_}</b>";
	    }
	    if ($revsym{$br})  {
		if ($revsym{$_}) {
		    output "; ";
		} else {
		    output "<BR>";
		}
		output "Branch: <b>$revsym{$br}</b>";
	    }
            if ($branchpoint{$_}) {
                if ($revsym{$br} || $revsym{$_}) {
                    output "; ";
                } else {
                    output "<BR>";
                }
                output "Branch point for: <b>$branchpoint{$_}</b>\n";
            }
	    # Find the previous revision on this branch.
	    @prevrev = split(/\./, $_);
	    if (--$prevrev[$#prevrev] == 0) {
		# If it was X.Y.Z.1, just make it X.Y
		if ($#prevrev > 1) {
		    pop(@prevrev);
		    pop(@prevrev);
		} else {
		    # It was rev 1.1 (XXX does CVS use revisions
		    # greater than 1.x?)
		    if ($prevrev[0] != 1) {
			output "<i>* I can't figure out the previous revision! *</i>\n";
		    }
		}
	    }
	    if ($prevrev[$#prevrev] != 0) {
		$prev = join(".", @prevrev);
		output "<BR><A HREF=\"$scriptwhere?r1=$prev";
		output "&r2=$_\">Diffs to $prev</A>\n";
		#
		# Plus, if it's on a branch, and it's not a vendor branch,
		# offer to diff with the immediately-preceding commit if it
		# is not the previous revision as calculated above
		# and if it is on the HEAD (or at least on a higher branch)
		# (e.g. change gets committed and then brought
		# over to -stable)
		if (!/^1\.1\.1\.\d+$/ && ($i != $#revorder) &&
					($prev ne $revorder[$i+1])) {
		    @tmp1 = split(/\./, $revorder[$i+1]);
		    @tmp2 = split(/\./, $_);
		    if ($#tmp1 < $#tmp2) {
			output "; <A HREF=\"$scriptwhere?r1=$revorder[$i+1]";
			output "&r2=$_\">Diffs to $revorder[$i+1]</A>\n";
		    }
		}
	    }
            if ($state{$_} eq "dead") {
                output "<BR><B><I>FILE REMOVED</I></B>\n";
            }
            output "<PRE>\n";
            output htmlify($log{$_}, 1);
            output "</PRE><HR NOSHADE>\n";

	}
display_diff_footer($sel, \@revorder, \@branchnames);
}


sub display_diff_footer ($$$) {
    local ($^W) = 0; # disable warnings
    my ($sel, $refrevorder, $refbranchnames) = @_;
    my (@revorder) = @$refrevorder;
    my (@branchnames) = @$refbranchnames;

    output "<A NAME=diff>\n";
    output "This form allows you to request diff's between any two\n";
    output "revisions of a file.  You may select a symbolic revision\n";
    output "name using the selection box or you may type in a numeric\n";
    output "name using the type-in text box.\n";
    output "</A><P>\n";
    output "<FORM METHOD=\"GET\" ACTION=\"${scriptwhere}.diff\">\n";
    output "<INPUT TYPE=HIDDEN NAME=\"cvsroot\" VALUE=\"$cvstree\">\n"
	if cvsroot();

    output "Diffs between \n";
    output "<SELECT NAME=\"r1\">\n";
    output "<OPTION VALUE=\"text\" SELECTED>Use Text Field\n";
    output $sel;
    output "</SELECT>\n";
    output "<INPUT TYPE=\"TEXT\" NAME=\"tr1\" VALUE=\"$revorder[$#revorder]\">\n";
    output " and \n";
    output "<SELECT NAME=\"r2\">\n";
    output "<OPTION VALUE=\"text\" SELECTED>Use Text Field\n";
    output $sel;
    output "</SELECT>\n";
    output "<INPUT TYPE=\"TEXT\" NAME=\"tr2\" VALUE=\"$revorder[0]\">\n";
    output "<BR><INPUT TYPE=RADIO NAME=\"f\" VALUE=u CHECKED>Unidiff<br>\n";
    output "<INPUT TYPE=RADIO NAME=\"f\" VALUE=c>Context diff<br>\n";
    output "<INPUT TYPE=RADIO NAME=\"f\" VALUE=s>Side-by-Side<br>\n";
    output "<INPUT TYPE=SUBMIT VALUE=\"Get Diffs\">\n";
    output "</FORM>\n";
    output "<HR noshade>\n";
    output "<A name=branch>\n";
    output "You may select to see revision information from only\n";
    output "a single branch.\n";
    output "</A><P>\n";
    output "<FORM METHOD=\"GET\" ACTION=\"$scriptwhere\">\n";
    output qq{<input type=hidden name=cvsroot value=$cvstree>\n} if cvsroot();
    output "Branch: \n";
    output "<SELECT NAME=\"only_on_branch\">\n";
    output "<OPTION VALUE=\"\"";
    output " SELECTED" if ($req->param("only_on_branch") eq "");
    output ">Show all branches\n";
    foreach (sort @branchnames) {
	output "<OPTION";
	output " SELECTED" if ($req->param("only_on_branch") eq $_);
	output ">${_}\n";
    }
    output "</SELECT>\n";
    output "<INPUT TYPE=SUBMIT VALUE=\"View Branch\">\n";
    output "</FORM>\n";
    output html_footer();
    output "</BODY></HTML>\n";
}

