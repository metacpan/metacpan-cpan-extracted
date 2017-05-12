#!perl

# Name: Run HTML::Parser from libwww-perl on the www.perl.com frontpage
# Require: 5.002
# Desc:


# This test runs the HTML::Parser from libwww-perl on the www.perl.com
# frontpage.



package MyParser;
@ISA=qw(HTML::Parser);

sub new
{
   @tags = ();
   my $class = shift;
   $class->SUPER::new(@_);
}

sub start
{
    my($self, $tag, $attr, $attrseq, $origtext) = @_;
    push(@tags, "<$tag>");
}

sub end
{
    my($self, $tag, $origtext) = @_;
    push(@tags, "</$tag>");
}

package main;

$HTML=<<'EOT';  # Dump of www.perl.com at 1997-01-04
<HTML>
<HEAD>
<TITLE>The www.perl.com Home Page</TITLE>

</HEAD>

<BODY BGCOLOR="#FFFFFF" LINK="#006666" VLINK="#AA0000" ALINK="#006666">

<!-- begin header -->
<A HREF="http://perl-ora.songline.com/universal/header.map"><IMG SRC="http://perl-ora.songline.com/graphics/header-nav.gif" HEIGHT="18" WIDTH="515" ALT="Nav bar" BORDER="0" usemap="#header-nav"></A>

<map name="header-nav">
<area shape="rect" alt="Perl.com" coords="5,1,103,17" href="http://www.perl.com/index.html">
<area shape="rect" alt="CPAN" coords="114,1,171,17" href="http://www.perl.com/CPAN/CPAN.html">
<area shape="rect" alt="Perl Language" coords="178,0,248,16" href="http://language.perl.com/">
<area shape="rect" alt="Perl Reference" coords="254,0,328,16" href="http://reference.perl.com/">
<area shape="rect" alt="Perl Conference" coords="334,0,414,17" href="http://conference.perl.com">
<area shape="rect" alt="Programming Republic of Perl" coords="422,0,510,17" href="http://republic.perl.com">
</map>

<!-- end header -->

<TABLE BORDER="0" CELLSPACING="0" CELLPADDING="10">
<TR>
<TD WIDTH="22%" VALIGN="MIDDLE">
<CENTER><IMG SRC="graphics/perl_id_313c.gif" ALT="Programming Republic of Perl" WIDTH="90" HEIGHT="90" ALIGN="bottom" BORDER="0"></CENTER>
</TD>

<TD WIDTH="78%" VALIGN="TOP">
<IMG SRC="graphics/perlhome_header.jpg" ALT="www.perl.com Home Page" WIDTH="400" HEIGHT="130" ALIGN="BOTTOM" BORDER="0">
</TD></TR>

<!-- begin sidebar -->
<TR>
<TD WIDTH="22%" VALIGN="TOP" BGCOLOR="#FFFED3">
<A HREF="http://www.perl.com/about.html"><FONT SIZE="2">About www.perl.com</FONT></A><BR>
<H4><FONT SIZE="4" COLOR="#000000">CPAN</FONT></H4>
<DL>
<DT><A HREF="/CPAN/README.html"><FONT SIZE="2">About</FONT></A><BR>
<A HREF="/CPAN/CPAN.html"><FONT SIZE="2">Overview</FONT></A><BR>
<A HREF="/CPAN/ROADMAP.html"><FONT SIZE="2">Roadmap</FONT></A><BR>
<A HREF="/CPAN/RECENT.html"><FONT SIZE="2">Recent</FONT></A>
</DT>

<DT><A HREF="/CPAN/"><FONT SIZE="2">Nearest CPAN Site</FONT></A></DT>
<DT><A HREF="/CPAN/SITES.html"><FONT SIZE="2">List of CPAN Sites</FONT></A></DT>
</DL>

<H4><FONT SIZE="4" COLOR="#000000">The Perl Language</FONT></H4>
<P><FONT SIZE="2">Get the </FONT><A HREF="http://www.perl.com/latest.html"><FONT SIZE="2">latest version</FONT></A><FONT SIZE="2"> of Perl (5.004_04)</FONT>.</P>

<H4><FONT SIZE="2">Overview</FONT></H4>

<A HREF="http://language.perl.com/admin/whats_new.html"><FONT SIZE="2">Perl News</FONT></A><BR>
<A HREF="http://language.perl.com/info/synopsis.html"><FONT SIZE="2">What is Perl?</FONT></A><BR>
<A HREF="http://language.perl.com/info/perl5-brief.html"><FONT SIZE="2">What's New in Perl5?</FONT></A>


<H4><FONT SIZE="2">Perl Software</FONT></H4>

<A HREF="http://language.perl.com/info/software.html"><FONT SIZE="2">Download Software</FONT></A><BR>
<A HREF="http://language.perl.com/info/documentation.html"><FONT SIZE="2">Documentation</FONT></A><BR>
<A HREF="http://language.perl.com/faq/index.html"><FONT SIZE="2">FAQs</FONT></A><BR>
<A HREF="http://language.perl.com/info/support.html"><FONT SIZE="2">Support</FONT></A><BR>
<A HREF="http://language.perl.com/info/training.html"><FONT SIZE="2">Training</FONT></A><BR>
<A HREF="http://language.perl.com/bugs/index.html"><FONT SIZE="2">Bug Reports</FONT></A>

<H4><FONT SIZE="2">Miscellaneous</FONT></H4>

<A HREF="http://orwant.www.media.mit.edu/the_perl_journal/"><FONT SIZE="2"><I>The Perl Journal</I></FONT></A><BR>
<A HREF="http://www.perl.org/"><FONT SIZE="2"><I>The Perl Institute</I></FONT></A><BR>
<A HREF="http://language.perl.com/versus/index.html"><FONT SIZE="2">Advocacy</FONT></A><BR>
<A HREF="http://language.perl.com/info/security.html"><FONT SIZE="2">Security</FONT></A><BR>
<A HREF="/CPAN/authors/00whois.html"><FONT SIZE="2">Who's Who?</FONT></A>

<P>
<HR ALIGN="LEFT" NOSHADE>
</P>

<H4><FONT SIZE="4" COLOR="#000000">Perl Reference</FONT></H4> 


<FORM METHOD="POST" ACTION="http://reference.perl.com/search.cgi">
<H5>Search Perl Reference: <INPUT TYPE="TEXT" NAME="arg" SIZE="15" MAXLENGTH="50"></H5>
</FORM>

<DL>
<DT><A HREF="http://reference.perl.com/query.cgi?books"><FONT SIZE="2">Books and Magazines</FONT></A></DT>
<DT><A HREF="http://reference.perl.com/query.cgi?cgi"><FONT SIZE="2">CGI</FONT></A></DT>
<DT><A HREF="http://reference.perl.com/query.cgi?communications"><FONT SIZE="2">Communications</FONT></A></DT>
<DT><A HREF="http://reference.perl.com/query.cgi?conversion"><FONT SIZE="2">Conversion Utilities</FONT></A></DT>
<DT><A HREF="http://reference.perl.com/query.cgi?corba"><FONT SIZE="2">CORBA</FONT></A></DT>
<DT><A HREF="http://reference.perl.com/query.cgi?courses"><FONT SIZE="2">Courses and Training</FONT></A><BR>

<FONT SIZE="1">(see the </FONT><A HREF="http://reference.perl.com/query.cgi?tutorials+index"><FONT SIZE="1">tutorials section</FONT></A><FONT SIZE="1"> for <BR>
Web-based courses)</FONT></DT>
<DT><A HREF="http://reference.perl.com/query.cgi?database"><FONT SIZE="2">Database</FONT></A></DT>
<DT><A HREF="http://reference.perl.com/query.cgi?debug"><FONT SIZE="2">Debugging</FONT></A></DT>
<DT><A HREF="http://reference.perl.com/query.cgi?editors"><FONT SIZE="2">Editors</FONT></A></DT>
<DT><A HREF="http://reference.perl.com/query.cgi?geographical"><FONT SIZE="2">Geographical Apps</FONT></A></DT>
<DT><A HREF="http://reference.perl.com/query.cgi?graphics"><FONT SIZE="2">Graphics and Imaging</FONT></A></DT>
<DT><A HREF="http://reference.perl.com/query.cgi?http"><FONT SIZE="2">HTTP</FONT></A></DT>
<DT><A HREF="http://reference.perl.com/query.cgi?lists"><FONT SIZE="2">Lists</FONT></A></DT>
<DT><A HREF="http://reference.perl.com/query.cgi?mac"><FONT SIZE="2">Macintosh</FONT></A></DT>
<DT><A HREF="http://reference.perl.com/query.cgi?mail"><FONT SIZE="2">Mail and USENET News</FONT></A></DT>
<DT><A HREF="http://reference.perl.com/query.cgi?net"><FONT SIZE="2">Network Programming</FONT></A></DT>
<DT><A HREF="http://reference.perl.com/query.cgi?newsgroups"><FONT SIZE="2">Newsgroups</FONT></A></DT>
<DT><A HREF="http://reference.perl.com/query.cgi?oo"><FONT SIZE="2">Object-Oriented Programming</FONT></A></DT>
<DT><A HREF="http://reference.perl.com/query.cgi?oddities"><FONT SIZE="2">Oddities</FONT></A></DT>
<DT><A HREF="http://reference.perl.com/query.cgi?porting"><FONT SIZE="2">Porting</FONT></A></DT>
<DT><A HREF="http://reference.perl.com/query.cgi?programming"><FONT SIZE="2">Programming</FONT></A></DT>
<DT><A HREF="http://reference.perl.com/query.cgi?regexp"><FONT SIZE="2">Regular Expressions</FONT></A></DT>
<DT><A HREF="http://reference.perl.com/query.cgi?releases"><FONT SIZE="2">Releases</FONT></A></DT>
<DT><A HREF="http://reference.perl.com/query.cgi?screen"><FONT SIZE="2">Screen I/O</FONT></A></DT>
<DT><A HREF="http://reference.perl.com/query.cgi?security"><FONT SIZE="2">Security</FONT></A></DT>
<DT><A HREF="http://reference.perl.com/query.cgi?sort"><FONT SIZE="2">Sorting</FONT></A></DT>
<DT><A HREF="http://reference.perl.com/query.cgi?statistics"><FONT SIZE="2">Statistics</FONT></A></DT>
<DT><A HREF="http://reference.perl.com/query.cgi?style"><FONT SIZE="2">Style Guides</FONT></A></DT>
<DT><A HREF="http://reference.perl.com/query.cgi?sysadmin"><FONT SIZE="2">Sys Admin</FONT></A></DT>
<DT><A HREF="http://reference.perl.com/query.cgi?text"><FONT SIZE="2">Text Tools</FONT></A></DT>
<DT><A HREF="http://reference.perl.com/query.cgi?time"><FONT SIZE="2">Time</FONT></A></DT>
<DT><A HREF="http://reference.perl.com/query.cgi?tutorials"><FONT SIZE="2">Tutorials</FONT></A></DT>
<DT><A HREF="http://reference.perl.com/query.cgi?ui"><FONT SIZE="2">User Interfaces</FONT></A></DT>
<DT><A HREF="http://reference.perl.com/query.cgi?webadmin"><FONT SIZE="2">Web Admin</FONT></A></DT>
<DT><A HREF="http://reference.perl.com/query.cgi?windows"><FONT SIZE="2">Windows 3.1<BR> Windows 95 <BR> Windows NT</FONT></A></DT>
</DL>

<A HREF="http://www.ora.com/perl/"><IMG SRC="graphics/ora_logo.gif" ALT="O'Reilly logo" WIDTH="90" HEIGHT="16" ALIGN="BOTTOM" BORDER="0"></A>
</TD>

<!-- end sidebar -->




<TD WIDTH="78%" VALIGN="top">

<H2><FONT COLOR="#AA0000">The Perl Developer Update</font></H2>
<H1>A Decade of Perl</h1>
<HR>
<H2>Perl is Ten Years Old</H2> 
Larry Wall shares with us some insight into the
origins of Perl on the occasion of its birthday,
officially December 18th, 1987.

<h4>Why is December 18th considered Perl's Birthday?</h4>

That is the day I turned Perl version 0 into Perl version 1, checked it
in under RCS, and posted it to Usenet for the first time.

<h4>Where was its birth place and on what kind of machine?</h4>

Perl was born in Santa Monica, CA, on a VAX 11/780 running BSD.
(Though gestation of Perl 0 was on a VAX 750.)  At the time I was
working for Burroughs (soon to be Unisys).

<h4>What were your thoughts when you released it into the world?</h4>

I thought people would find Perl to be a vast improvement on sed and
awk, and, to a lesser extent, the various shells.  I didn't hope to
replace C, though there were a certain number of programmers who
essentially abandoned C as soon as they had Perl.
<p>
I didn't, of course, anticipate the use of Perl to prototype the Web, but
I basically understood that Perl would be successful, because I'd already
had experience with rn and patch, and had a pretty good notion that other
people would like the same things I like.</p>

<h4>At what age did you begin to feel that Perl had a life
apart from you? </h4> 

42.  :-)

<p>You mean, as in the phrase "Get a life!"?  I dunno.  In a sense, it
started having a life of its own as soon as I posted it to Usenet.  In
another sense, it started having its own life when Perl 5 came out with
an official extension mechanism.  But in yet another sense, Perl only
started having its own life a year or so ago when I started letting
other people take the lead in maintaining and developing it.  These
days I'm in a mostly advisory role to Perl development, much like with
my teenage daughter.  (As in, "No way am I gonna let you go out with
that jerk!")</p>

<h4>Is there a Mother of Perl?</h4>

I suppose there must be, since my wife's brother Mark Biggar claims to
be the maternal uncle of Perl, but my wife Gloria has never insisted on
being designated the Mother of Perl.  Perhaps it's her Protestant
upbringing...

<blockquote>Do you have any birthday wishes to offer
for Perl?  If so, please send them to the <A HREF="mailto:dale@songline.com">
editor</A> and I will post them here.</blockquote>
<H2><FONT COLOR="#AA0000">Dates Set for 2nd Perl Conference</font></H2>
Several people have asked if O'Reilly has set
the place and time for the next Perl Conference.  
Brian Erwin of O'Reilly was able to confirm that 1998 Perl
Conference will once again be held at the
Fairmont Hotel in San Jose.  The dates are August 17-20. 
We'll keep you posted as more information becomes
available.

<P>
Note: If you need help selecting the right version
of Perl for your computer, see our <A HREF="latest.html">Latest file.</A>   
<P>
<B>---
December 20, 1997</B>
<P>
Previous Updates:
<ul><li><A HREF="971127.html">Java and Perl Integration</A>
<li><A HREF="971107.html">O'Reilly Ships Perl Resource Kit</A>
</ul>
<P>
The Perl Developer Update will help to keep you informed of
news and events happening here at www.perl.com and in 
the Perl community.  It will also carry announcements of
commercial products and services.  If you have information
for a future update, please send it to: <A HREF="mailto:dale@songline.com">
Dale Dougherty</A>.
<P>
<hr>
www.perl.com is managed by
<A HREF="http://www.songline.com">Songline Studios</A>
on behalf of <A HREF="http://www.oreilly.com/">O'Reilly & Associates</A>.
www.perl.com is hosted on a Linux box running Apache (for machine specs,
click <A HREF="specs.html">here</A>.)   If you have comments
or questions relating to the site (ie, not language related questions), please
contact <A HREF="mailto:dustin@songline.com">Dustin Mollo</A>.
</TD>
</TR>

</TD></TR>
</TABLE>
</BODY>
</HTML>

EOT


# Split the HTML into suitable chunks
@HTML = grep length, unpack(("a1024" x 1000), $HTML);

#print length($HTML), "\n";
#print int(@HTML), "\n";


require 'benchlib.pl';


&runtest(0.004, <<'ENDTEST');

   my $p = MyParser->new;

   for (@HTML) {
      $p->parse($_);
   }
   $p->eof;
   undef($p);

ENDTEST

#print "@MyParser::tags";
exit;

#-------------------------------------------------------copy---------
package HTML::Parser;

# $Id: htmlparser.t,v 1.3 1998/01/07 09:42:23 aas Exp $

use strict;
#use HTML::Entities ();

use vars qw($VERSION);
$VERSION = sprintf("%d.%02d", q$Revision: 1.3 $ =~ /(\d+)\.(\d+)/);


sub new
{
    my $class = shift;
    my $self = bless { '_buf'            => '',
		       '_strict_comment' => 0,
		     }, $class;
    $self;
}


# A note about how Netscape does it:
#
# It parse <xmp> in the depreceated 'literal' mode, i.e. no tags are
# recognized until a </xmp> is found.
# 
# <listing> is parsed like <pre>, i.e. tags are recognized.  <listing>
# are presentend in smaller font than <pre>
#
# Netscape does not parse this comment correctly (it terminates the comment
# too early):
#
#    <! -- comment -- --> more comment -->
#
# Netscape does not allow space after the initial "<" in the start tag.
# Like this "<a href='gisle'>"
#
# Netscape ignores '<!--' and '-->' within the <SCRIPT> and <STYLE> tag.
# This is used as a trick to make non-script-aware browsers ignore
# the scripts.


sub parse
{
    my $self = shift;
    my $buf = \ $self->{'_buf'};
    unless (defined $_[0]) {
	# signals EOF (assume rest is plain text)
	$self->text($$buf) if length $$buf;
	$$buf = '';
	return $self;
    }
    $$buf .= $_[0];
    my $netscape_comment = !$self->{'_strict_comment'};

    # Parse html text in $$buf.  The strategy is to remove complete
    # tokens from the beginning of $$buf until we can't deside whether
    # it is a token or not, or the $$buf is empty.

  TOKEN:
    while (1) {

	# First we try to pull off any plain text (anything before a "<" char)
	if ($$buf =~ s|^([^<]+)||) {
	    unless (length $$buf) {
		my $text = $1;
		# At the end of the buffer, we should not parse white space
		# but leave it for parsing on the next round.
		if ($text =~ s|(\s+)$||) {
		    $$buf = $1;
                # Same treatment for chopped up entites.
		} elsif ($text =~ s/(&(?:(?:\#\d*)?|\w*))$//) {
		    $$buf = $1;
		};
		$self->text($text);
		last TOKEN;
	    } else {
		$self->text($1);
	    }

	# Netscapes buggy comments are easy to handle
	} elsif ($netscape_comment && $$buf =~ m|^<!--|) {
	    if ($$buf =~ s|^<!--(.*?)-->||s) {
		$self->comment($1);
	    } else {
		last TOKEN;  # must wait until we see the end of it
	    }

	# Then, markup declarations (usually either <!DOCTYPE...> or a comment)
	} elsif ($$buf =~ s|^(<!)||) {
	    my $eaten = $1;
	    my $text = '';
	    my @com = ();  # keeps comments until we have seen the end
	    # Eat text and beginning of comment
	    while ($$buf =~ s|^(([^>]*?)--)||) {
		$eaten .= $1;
		$text .= $2;
		# Look for end of comment
		if ($$buf =~ s|^((.*?)--)||s) {
		    $eaten .= $1;
		    push(@com, $2);
		} else {
		    # Need more data to get all comment text.
		    $$buf = $eaten . $$buf;
		    last TOKEN;
		}
	    }
	    # Can we finish the tag
	    if ($$buf =~ s|^([^>]*)>||) {
		$text .= $1;
		$self->declaration($text) if $text =~ /\S/;
		# then tell about all the comments we found
		for (@com) { $self->comment($_); }
	    } else {
		$$buf = $eaten . $$buf;  # must start with it all next time
		last TOKEN;
	    }

        # Should we look for 'processing instructions' <? ...> ??
	#} elsif ($$buf =~ s|<\?||) {
	    # ...

	# Then, look for a end tag
	} elsif ($$buf =~ s|^</||) {
	    # end tag
	    if ($$buf =~ s|^([a-zA-Z][a-zA-Z0-9\.\-]*)(\s*>)||) {
		$self->end(lc($1), "</$1$2");
	    } elsif ($$buf =~ m|^[a-zA-Z]*[a-zA-Z0-9\.\-]*\s*$|) {
		$$buf = "</" . $$buf;  # need more data to be sure
		last TOKEN;
	    } else {
		# it is plain text after all
		$self->text("</");
	    }

	# Then, finally we look for a start tag
	} elsif ($$buf =~ s|^(<([a-zA-Z]+)>)||) {
	    # special case plain start tags for slight speed-up (2.5%)
	    $self->start(lc($2), {}, [], $1);

	} elsif ($$buf =~ s|^<||) {
	    # start tag
	    my $eaten = '<';

	    # This first thing we must find is a tag name.  RFC1866 says:
	    #   A name consists of a letter followed by letters,
	    #   digits, periods, or hyphens. The length of a name is
	    #   limited to 72 characters by the `NAMELEN' parameter in
	    #   the SGML declaration for HTML, 9.5, "SGML Declaration
	    #   for HTML".  In a start-tag, the element name must
	    #   immediately follow the tag open delimiter `<'.
	    if ($$buf =~ s|^(([a-zA-Z][a-zA-Z0-9\.\-]*)\s*)||) {
		$eaten .= $1;
		my $tag = lc $2;
		my %attr;
		my @attrseq;

		# Then we would like to find some attributes
                #
                # Arrgh!! Since stupid Netscape violates RCF1866 by
                # using "_" in attribute names (like "ADD_DATE") of
                # their bookmarks.html, we allow this too.
		while ($$buf =~ s|^(([a-zA-Z][a-zA-Z0-9\.\-_]*)\s*)||) {
		    $eaten .= $1;
		    my $attr = lc $2;
		    my $val;
		    # The attribute might take an optional value (first we
		    # check for an unquoted value)
		    if ($$buf =~ s|(^=\s*([^\"\'>\s][^>\s]*)\s*)||) {
			$eaten .= $1;
			$val = $2;
			#HTML::Entities::decode($val);
		    # or quoted by " or '
		    } elsif ($$buf =~ s|(^=\s*([\"\'])(.*?)\2\s*)||s) {
			$eaten .= $1;
			$val = $3;
			#HTML::Entities::decode($val);
                    # truncated just after the '=' or inside the attribute
		    } elsif ($$buf =~ m|^(=\s*)$| or
			     $$buf =~ m|^(=\s*[\"\'].*)|s) {
			$$buf = "$eaten$1";
			last TOKEN;
		    } else {
			# assume attribute with implicit value
			$val = $attr;
		    }
		    $attr{$attr} = $val;
		    push(@attrseq, $attr);
		}

		# At the end there should be a closing ">"
		if ($$buf =~ s|^>||) {
		    $self->start($tag, \%attr, \@attrseq, "$eaten>");
		} elsif (length $$buf) {
		    # Not a conforming start tag, regard it as normal text
		    $self->text($eaten);
		} else {
		    $$buf = $eaten;  # need more data to know
		    last TOKEN;
		}

	    } elsif (length $$buf) {
		$self->text($eaten);
	    } else {
		$$buf = $eaten . $$buf;  # need more data to parse
		last TOKEN;
	    }

	} else {
	    #die if length($$buf);  # This should never happen
	    last TOKEN; 	    # The buffer should be empty now
	}
    }

    $self;
}


sub eof
{
    shift->parse(undef);
}


sub parse_file
{
    my($self, $file) = @_;
    no strict 'refs';  # so that a symbol ref as $file works
    local(*F);
    unless (ref($file) || $file =~ /^\*[\w:]+$/) {
	# Assume $file is a filename
	open(F, $file) || die "Can't open $file: $!";
	$file = \*F;
    }
    my $chunk = '';
    while(read($file, $chunk, 1024)) {
	$self->parse($chunk);
    }
    close($file);
    $self->eof;
}


sub strict_comment
{
    my $self = shift;
    my $old = $self->{'_strict_comment'};
    $self->{'_strict_comment'} = shift if @_;
    return $old;
}


sub netscape_buggy_comment  # legacy
{
    my $self = shift;
    my $old = !$self->strict_comment;
    $self->strict_comment(!shift) if @_;
    return $old;
}


sub text
{
    # my($self, $text) = @_;
}

sub declaration
{
    # my($self, $decl) = @_;
}

sub comment
{
    # my($self, $comment) = @_;
}

sub start
{
    # my($self, $tag, $attr, $attrseq, $origtext) = @_;
    # $attr is reference to a HASH, $attrseq is reference to an ARRAY
}

sub end
{
    # my($self, $tag, $origtext) = @_;
}

1;
