use strict;
local $^W = 0;
our $jobname;
require './t/defs.pm';

use Combine::XWI;
use Combine::UA;
use Combine::FromHTML;
use Digest::MD5; #used by UA
use HTTP::Date; #str2time
use Combine::LogSQL;
use Combine::Config;
use Getopt::Long;
my $configfile;
my $dbase;
my $enableprint;
my $showtext;
my $doURL;
GetOptions('configfile:s' => \$configfile, 'enableprint', => \$enableprint,
	   'showtext' => \$showtext, 'url:s' => \$doURL);

use Cwd;

Combine::Config::Init($jobname,getcwd . '/blib/conf');

my $log = new Combine::LogSQL "testFromHTML";
Combine::Config::Set('LogHandle', $log);

my %testurls;

%{$testurls{'http://combine.it.lth.se/CombineTests/anders.html'}} =
 ('url' => 'http://combine.it.lth.se/CombineTests/anders.html',
  'type' => 'text/html',
  'metacontent-type' => 'text/html; charset=iso-8859-1',
  'title' => 'Short CV for Anders Ardö',
#  'server' => 'Apache/1.3.26 (Unix) Debian GNU/Linux PHP/4.1.2',
#  'size' => '1582',
  'http://combine.it.lth.se/CombineTests/aa.gif' => '',
  'http://www.lub.lu.se/netlab/' => 'NetLab',
  'http://www.dtv.dk/' => 'DTV',
  'http://combine.it.lth.se/CombineTests/cv.html' => 'Full CV',
  'metadescription' => 'short_cv',
  'metakeywords' => 'short_cv, keyword',
  'metaresource-type' => 'document',
  'metacontent-type' => 'text/html',
  'Full Curriculum Vitae' => 'heading'
  );

%{$testurls{'http://combine.it.lth.se/CombineTests/I8_utf8.html'}} =
 ('url' => 'http://combine.it.lth.se/CombineTests/I8_utf8.html',
  'type' => 'text/html',
  'metacontent-type' => 'text/html',
  'title' => 'Short CV for Anders Ardö',
  'http://www.lub.lu.se/netlab/' => 'öäåÖÄÅ',
  'metadescription' => 'short_cv för Anders Ardö med äå',
  'metacontent-type' => 'text/html',
  'Heading m öäåÖÄÅ' => 'heading'
  );

#%{$testurls{'http://combine.it.lth.se/CombineTests/base.html'}} =
# ('url' => 'http://combine.it.lth.se/CombineTests/base.html',
#  'title' => 'Jane Larsen',
#  'type' => 'text/html',
#  'metagenerator' => "HKN's preprocessor",
#  'metacontent-type' => "text/html",
#  "http://www.lu.se/" => 'Lund University',
#  'http://spider.chemphys.lu.se/kfpeople/people.pl' => 'Current members',
#  'http://spider.chemphys.lu.se/kfpeople/' => 'People',
#  'http://spider.chemphys.lu.se/kfpubs/search.pl?authors=larsen,j' => 'Publications',
#  'mailto:spcatch1098@hotmail.com' => 'this address',
#  'http://spider.chemphys.lu.se/kfpeople/people.pl?id=93ed948a&isrobot=foo' => 'Email for bots',
#  'http://spider.chemphys.lu.se/kfpeople/mail_links.pl?id=bdbd' => 'email',
#  'http://www.chemphys.lu.se/chemphyslogo.gif' => 'Department of Chemical Physics',
#  'http://spider.chemphys.lu.se/kfpeople/mugshots/jane.jpg' => '[Jane :-) ]',
##  'Jane Larsen' => 'heading',
##  'People at Chemical Physics' => 'heading'
#  'Jane Larsen; People at Chemical Physics' => 'heading'
#  );

%{$testurls{'http://combine.it.lth.se/CombineTests/metatest.html'}} =
 ('url' => 'http://combine.it.lth.se/CombineTests/metatest.html',
  'title' => '',
  'type' => 'text/html',
  'metacontent-type' => 'text/html',
  'http://combine.it.lth.se/CombineTests/mail_links.pl/667' => "Earle's Email",
  'http://combine.it.lth.se/CombineTests/people.pl?turing=&id=877' => 'Email contact',
  'metarobots' => 'noindex,nofollow',
  'METArobots' => 'noindex,nofollow',
  'Email addresses' => 'heading'
  );

%{$testurls{'http://combine.it.lth.se/CombineTests/I8.html'}} =
 ('url' => 'http://combine.it.lth.se/CombineTests/I8.html',
  'title' => 'Short CV for Anders Ardö',
  'type' => 'text/html',
  'metacontent-type' => 'text/html',
  'http://www.lub.lu.se/netlab/' => 'öäåÖÄÅ',
  'Heading m öäåÖÄÅ' => 'heading',
  'metadescription' => 'short_cv för Anders Ardö med äå',
#  'Rsummary' => 'shortcv för Anders Ardö med äå Anders Ar'
  );

%{$testurls{'file:t/data/malaria.html'}}=
('url' => 'file:t/data/malaria.html',
 'title' => 'GeneQuiz - Analysis of Plasmodium falciparum genome',
 'type' => 'text/html',
 'metacontent-type' => 'text/html',
 'http://www.tigr.org/tdb/edb/pfdb/pfdb.html' => 'Plasmodium falciparum Genome Database',
 'http://www.ncbi.nlm.nih.gov/entrez/query.fcgi?cmd=Retrieve&db=PubMed&list_uids=9804551&dopt=Abstract' => 'Gardner et al. (1998). Science 282:1126-1132.',
 'http://columba.ebi.ac.uk:8765/gq/r2h?filename=/ebi/genequiz/1999/pf9902/sum/PF9902.function.rdb&nodetail=1' => 'clock representation of assignments',
 'http://columba.ebi.ac.uk:8765/gq/selsum?project=PF9902&criteria=ide&title=Genequiz+analysis+of+%3CI%3EPlasmodium+falciparum%3C/I%3E+(e.g.,+PFB0025c)' => 'by protein identifier',
 'http://columba.ebi.ac.uk:8765/gq/selsum?project=PF9902&criteria=fun&title=Genequiz+analysis+of+%3CI%3EPlasmodium+falciparum%3C/I%3E' => 'by functional class',
 'http://www.sander.ebi.ac.uk/' => '[Sander group [defunct]@EMBL-EBI]',
 'file:///clocks/PF9902.function.gif' => 'clock representation of assignments',
 'http://www.sander.ebi.ac.uk/images/button_sander_ebi.gif' => '[Sander group [defunct]@EMBL-EBI]',
 'Plasmodium falciparum' => 'heading',
 );

%{$testurls{'file:t/data/malaria_xml.html'}}=
('url' => 'file:t/data/malaria_xml.html',
 'title' => 'GeneQuiz - Analysis of Plasmodium falciparum genome',
 'type' => 'text/html',
 'metacontent-type' => 'text/html',
 'http://www.tigr.org/tdb/edb/pfdb/pfdb.html' => 'Plasmodium falciparum Genome Database',
 'http://www.ncbi.nlm.nih.gov/entrez/query.fcgi?cmd=Retrieve&db=PubMed&list_uids=9804551&dopt=Abstract' => 'Gardner et al. (1998). Science 282:1126-1132.',
 'http://columba.ebi.ac.uk:8765/gq/r2h?filename=/ebi/genequiz/1999/pf9902/sum/PF9902.function.rdb&nodetail=1' => 'clock representation of assignments',
 'http://columba.ebi.ac.uk:8765/gq/selsum?project=PF9902&criteria=ide&title=Genequiz+analysis+of+%3CI%3EPlasmodium+falciparum%3C/I%3E+(e.g.,+PFB0025c)' => 'by protein identifier',
 'http://columba.ebi.ac.uk:8765/gq/selsum?project=PF9902&criteria=fun&title=Genequiz+analysis+of+%3CI%3EPlasmodium+falciparum%3C/I%3E' => 'by functional class',
 'http://www.sander.ebi.ac.uk/' => '[Sander group [defunct]@EMBL-EBI]',
 'file:///clocks/PF9902.function.gif' => 'clock representation of assignments',
 'http://www.sander.ebi.ac.uk/images/button_sander_ebi.gif' => '[Sander group [defunct]@EMBL-EBI]',
 'Plasmodium falciparum' => 'heading',
 );

my $ant_urls = scalar(keys %testurls);
print "1..$ant_urls\n";

if ($doURL) {$testurls{$doURL}{url}=$doURL;}
my $totOK=1;
my $i=0;
foreach my $url_str (keys(%testurls)) {
    if ($doURL && ($url_str ne $doURL)) { next;}
    print "\nDoing $url_str\n"  if $enableprint;
    $i++;
    my $OK=1;
    my $xwi = new Combine::XWI;
    $xwi->url($url_str);
    $xwi->url_add($url_str);

    print "GET: $url_str\n" if $enableprint;
    my @UaFetch = &Combine::UA::fetch($xwi);
    my ($code, $msg) = @UaFetch;
    my $httpResponse = "HTTP($code = \"$msg\") ";
    print "$httpResponse\n" if $enableprint;
    my $result = '';
    $xwi = &Combine::FromHTML::trans(\$result, $xwi, 'GuessHTML');
    
    print "XWI values\n" if $enableprint;
    my $base = $xwi->base;
    print "BASE: $base\n" if $enableprint;
    $xwi->url_rewind;
    my $url = $xwi->url_get;
    print "URL: $url\n" if $enableprint;
    if (${$testurls{$url_str}}{'url'} ne $url) { $OK=0; print "NOT OK: url\n" if $enableprint;}
    else { delete(${$testurls{$url_str}}{'url'}) ; }

    my $type = $xwi->type;
    print "TYPE: |$type|\n" if $enableprint;
    if (${$testurls{$url_str}}{'type'} ne $type) { $OK=0; print "NOT OK: type\n" if $enableprint;}
    else { delete(${$testurls{$url_str}}{'type'}) ; }

    my $title = $xwi->title;
    print "TITLE: |$title|\n" if $enableprint;
    if (${$testurls{$url_str}}{'title'} ne $title) { $OK=0; print "NOT OK: title\n" if $enableprint;}
    else { delete(${$testurls{$url_str}}{'title'}) ; }

    my $lastchecked = $xwi->fdate;
    if ($lastchecked) { $lastchecked = str2time($lastchecked) ; }
    else { $lastchecked = 'NULL'; }
    my $mdate = $xwi->mdate;
    if ($mdate) { $mdate =  str2time($mdate) ; }
    else { $mdate = $lastchecked; }
    my $expiredate = $xwi->edate;
    if ($expiredate) { $expiredate = str2time($expiredate) ; }
    else { $expiredate = 'NULL'; }
    print "LC: $lastchecked; MOD: $mdate; EXP: $expiredate\n" if $enableprint;

    my $length = $xwi->length;
#    if (${$testurls{$url_str}}{'size'} ne $length) { $OK=0; print "NOT OK: size\n" if $enableprint;}
#    else { delete(${$testurls{$url_str}}{'size'}) ; }

    my $server = $xwi->server;
#    if (${$testurls{$url_str}}{'server'} ne $server) { $OK=0; print "NOT OK: server\n" if $enableprint;}
#    else { delete(${$testurls{$url_str}}{'server'}) ; }

    my $nheadings = $xwi->heading_count;
    my $nlinks = $xwi->link_count;
    print "SERVER: $server; LEN: $length; #H: $nheadings; #L: $nlinks\n" if $enableprint;

    my $this = $xwi->text;
    my $lenip=length($$this);
    my $text = $$this;
    $this = substr($$this,0,40);
    print "IP($lenip): $this ...\n" if $enableprint;

    print "LINKS: $nlinks:\n" if $enableprint;
    $xwi->link_rewind;
    my $link_count = 1;
    while(1) { #links
	my ($urlstr, $netlocid, $urlid, $anchor, $ltype) = $xwi->link_get;
	if ($urlstr) {
	    print "$urlstr; |$anchor|\n" if $enableprint;
	    if (${$testurls{$url_str}}{$urlstr} ne $anchor) { $OK=0; print "NOT OK: link $urlstr, |$anchor|\n" if $enableprint;}
	    else { delete(${$testurls{$url_str}}{$urlstr}) ; }
	} else { last; }
	last if ($link_count++ >= 100);  # limit on number of links
    }

    print "HEADINGS: $nheadings:\n" if $enableprint;
    $xwi->heading_rewind;
    while (1) {
	$this = $xwi->heading_get or last; 
	print "|$this|\n" if $enableprint;
	if (${$testurls{$url_str}}{$this} ne 'heading') { $OK=0; print "NOT OK: heading: $this\n" if $enableprint;}
	else { delete(${$testurls{$url_str}}{$this}) ; }
    }

    print "META: \n" if $enableprint;
    $xwi->meta_rewind;
    my ($name,$content);
    my %seen;
    while (1) {
	($name,$content) = $xwi->meta_get;
	last unless $name;
	$content = substr($content,0,40);
	print "$name= |$content|\n" if $enableprint;
	if ($seen{$name}) { print "Have seen $name already - continue\n" if $enableprint; next; }
	$seen{$name}=1;
        if ( ($name eq 'Rsummary') ) {
	    if ( defined(${$testurls{$url_str}}{'Rsummary'}) ) {
		if (${$testurls{$url_str}}{'Rsummary'} ne $content) { $OK=0; print "NOT OK: Rsummary $content\n" if $enableprint;}
	        else { delete(${$testurls{$url_str}}{'Rsummary'}) ; }
	    }
	    next;
	}
	if (${$testurls{$url_str}}{"meta$name"} ne $content) { $OK=0; print "NOT OK: meta $name\n" if $enableprint;}
	else { delete(${$testurls{$url_str}}{"meta$name"}) ; }
    }

    my $metarobots = $xwi->metarobots;
    print "METArobots: $metarobots\n" if $enableprint;
    if (${$testurls{$url_str}}{'METArobots'} ne $metarobots) { $OK=0; print "NOT OK: METArobots $metarobots\n" if $enableprint;}
    else { delete(${$testurls{$url_str}}{'METArobots'}) ; }

    foreach my $v (keys(%{$testurls{$url_str}})) {
      print "NO MATCH: $v |${$testurls{$url_str}}{$v}|\n"  if $enableprint;
      $OK=0;
    }
    if ( $OK == 1 ) { print "ok $i\n"; }
    else { print "not ok $i\n"; }
    print "Text=\n$text\n" if $showtext && $enableprint;    
    if ($totOK==1) {$totOK=$OK;}
}

#if ( $totOK == 1 ) { print "ALL test pages OK\n"; }
#else { print "Some errors occured\n"; }
