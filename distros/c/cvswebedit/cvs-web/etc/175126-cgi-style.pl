# $Id: cgi-style.pl,v 1.2 1998/02/18 13:27:44 root Exp $
#
# Perl routines to encapsulate various elements of HTML page style.
# These are global variables used mostly by cvsweb.cgi

# The HTML title will be $title: /pathname
$title = "Your CVS Tree";

# The HTML to go inside the <H1> tag
$h1 = "Your CVS Tree";

# $intro is the HTML that is displayed along with the
# top-level tree
$intro = <<EOM;

This is a WWW interface to your CVS tree.
You can browse the file hierarchy by picking directories
(which have slashes after them, e.g. <b>src/</b>).
If you pick a file, you will see the revision history
for that file.
<p>
Selecting a revision number will download that revision of
the file.  There is a link at each revision to display
diffs between that revision and the previous one, and
a form at the bottom of the page that allows you to
display diffs between arbitrary revisions.
<p>
Please send any suggestions, comments, etc. to:
EOM

$intro .="<A HREF=\"mailto:".$administrator."\">".$administrator."</A>\n";
#

# $shortinstr is the HTML displayed at the top of non-top-level
# directory listings.
$shortinstr = <<EOM;
Click on a directory to enter that directory. Click on a file to display
its revision history and to get a chance to display diffs between revisions. 
EOM


# $tailhtml is the html for the bottom of the page
$tailhtml ="
<ADDRESS>
  <A HREF=\"mailto:$ENV{SERVER_ADMIN}\">$ENV{SERVER_ADMIN}</A>
</ADDRESS>";

sub html_header {
    my ($title) = @_;

    return "Content-type: text/html\n" . 
	"pragma: no-cache\n\n".
	"<html>\n<head><title>$title</title>\n</head>\n<body text=\"#000000\" bgcolor=\"#ffffff\">\n" .
	"<h1><font color=\"#660000\">$title</font></h1>\n";
}

sub html_footer {
    return "<hr><address> Bill Fenner &lt;fenner\@freebsd.org&gt; (cvsweb) and Martin.Cleaver\@BCS.org.uk (cvswebedit)<br>$hsty_date</address>\n";
}

1;

