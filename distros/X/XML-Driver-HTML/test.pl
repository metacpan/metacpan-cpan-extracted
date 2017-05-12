# XML::Driver::HTML
#
# Copyright (c) 2001 Michael Koehne <kraehe@copyleft.de>
#
# XML::Filter::HTML is free software. You can redistribute and/or modify
# this copy under terms of the GNU General Public License.

use strict;
use XML::Handler::YAWriter;
use XML::Driver::HTML;
use IO::File;
use Digest::MD5;
use vars qw($loaded %checksums $md5);

BEGIN { $| = 1; print "1..2\n"; print "loaded     ... "; }
END { print "not ok 1\n" unless $loaded; }

$loaded = 1;

%checksums = (
	'www.xml-edifact.org-EX-index.xhtml' => "d35b7799a07fcf09da6b58a859949919",
	'www.copyleft.de-index.xhtml' => "16bf4f246c4008c2e6b62f63693783ec",
	'www.cpan.org-index.xhtml' => "fccc3b62707afa1deb7e6023a05d4a1a"
	);

print "ok 1\n";

#------------------------------------------------------------------------------#

print "ByteStream ... ";

my $ya = new XML::Handler::YAWriter( 
    'AsFile' => "www.xml-edifact.org-EX-index.xhtml",
    'Pretty' => {
	'AddHiddenNewline'=>1,
	'AddHiddenAttrTab'=>1,
	'CatchEmptyElement'=>1
	}
    );

my $html = new XML::Driver::HTML(
    'Handler' => $ya,
    'Source' => { 'ByteStream' => new IO::File ( "<www.xml-edifact.org-EX-index.html" ) }
    );

$html->parse();

$md5=Digest::MD5->new->addfile(
	new IO::File( "<www.xml-edifact.org-EX-index.xhtml" )
    )->hexdigest;

print $md5." ... ";
print "not " if $md5 ne $checksums{'www.xml-edifact.org-EX-index.xhtml'};
print "ok 2\n";

#------------------------------------------------------------------------------#

print "SystemId   ... ";

$ya->{'AsFile'} = "www.copyleft.de-index.xhtml";

$html->parse(
    'Source' => {
    	'SystemId' => "www.copyleft.de-index.html",
    	'Encoding' => "iso-8859-1"
	}
    );

$md5=Digest::MD5->new->addfile(
	new IO::File( "<www.copyleft.de-index.xhtml" )
    )->hexdigest;

print $md5." ... ";
print "not " if $md5 ne $checksums{'www.copyleft.de-index.xhtml'};
print "ok 3\n";

#------------------------------------------------------------------------------#

print "String     ... ";

$ya->{'AsFile'} = "www.cpan.org-index.xhtml";
delete $ya->{'Pretty'}{'NoComments'};

my $cpan_index = <<'INDEX_HERE';
<!doctype html public "-//W3C//DTD HTML 3.2//EN">
<html>
<head>
<title>Comprehensive Perl Archive Network</title>
<!-- Copyright Jarkko Hietaniemi jhi@iki.fi 1998 All Rights Reserved -->
<!-- You may distribute this document either under the Artistic License
     (comes with Perl) or the GNU Public License, whichever suits you.  -->
<!-- $Id: index.html,v 1.8 1999/09/09 11:32:25 jhi Exp jhi $ -->
<link rev="made" href="mailto:cpan@perl.org">
<style type="text/css">
<!-- BODY { background: white; margin-left: 2%; margin-right: 2% } H1 { text-align: center } -->
</style>
</head>
<body>
<a name="top"></a>
<h1>CPAN: Comprehensive Perl Archive Network</h1>
<p>
Welcome to CPAN!   Here you will find All Things Perl.
</p>
<p>
CPAN is the <b>C</b>omprehensive <b>P</b>erl <b>A</b>rchive
<b>N</b>etwork.  <i>Comprehensive</i>: the aim is to contain all the Perl
material you will need.  <i>Archive</i>: 760 megabytes as of September 1999.
<i>Network</i>: CPAN is mirrored at more than one hundred <a
href="SITES.html">sites</a> around the world.
</p>
<ul>
  <li><a href="doc/index.html">documentation</a>
    <ul>	
      <li>standard documentation
      <ul>
        <li>Browsable:
	      <a href="doc/manual/html/index.html">[HTML]</a>
        <li>Archives:
      <a href="doc/manual/html/PerlDoc.tar.gz">[HTML&nbsp;1.6&nbsp;MB]</a>
      <a href="doc/manual/postscript/PerlDoc-5.005_02.ps.gz">[PostScript&nbsp;1.9&nbsp;MB]</a>
      <a href="authors/id/BMIDD/perlbook-5.005_02-a.tar.gz">[PDF&nbsp;3.0&nbsp;MB]</a>
      <a href="doc/manual/text/PerlDoc-5.005_02.txt.gz">[text&nbsp;1.0&nbsp;MB]</a>
      </ul>
      <li>Perl <a href="doc/FAQs/FAQ/html/index.html">Frequently Asked Questions</a> (with Answers)
      <li>all <a href="doc/FAQs/index.html">FAQs</a>
    </ul>
  <li><a href="modules/index.html">modules</a>
  <li><a href="scripts/index.html">scripts</a>
  <li><a href="ports/index.html">binary distributions ("ports")</a>
  <li><a href="src/index.html">source code</a>
  <li><a href="clpa/index.html">comp.lang.perl.announce archives</a>
  <li><a href="RECENT.html">recent arrivals</a>
</ul>
</p>
<hr>
<p>
You can <b>search</b>
<a href="http://search.cpan.org">all of CPAN</a>.
There are also alternative searching engines
<a href="http://theory.uwinnipeg.ca/search/cpan-search.html">for CPAN</a>
and
the documentation of <a href="http://ls6-www.informatik.uni-dortmund.de/CPAN.html">all modules</a>.
You can also check the
<a href="misc/cpan-faq.html">CPAN Frequently Asked Questions</a> list.
</p>
<hr>
<i>Yours Eclectically</i><br>
The Self-Appointed Master Librarian (OOK!) of the CPAN<br>
<i>Jarkko Hietaniemi</i><br>
<a href="mailto:cpan@perl.org">cpan@perl.org</a></br>
<a href="disclaimer.html">[Disclaimer]</a><br>
</pre>
1999-03-05
<hr>
</body>
</html>
INDEX_HERE

$html->parse(
    'Source' => { 'String' => $cpan_index }
    );

$md5=Digest::MD5->new->addfile(
	new IO::File( "<www.cpan.org-index.xhtml" )
    )->hexdigest;

print $md5." ... ";
print "not " if $md5 ne $checksums{'www.cpan.org-index.xhtml'};
print "ok 4\n";
print "\tinvalid www.cpan.org-index.xhtml because of HTML::TreeBuilder\n";

0;
