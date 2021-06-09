#!/usr/bin/perl -w

use IO::File;
use XML::LibXML;
use Getopt::Long qw(:config no_ignore_case);
use File::Basename qw(basename);
use POSIX; ##-- for strftime()
#use Date::Parse; ##-- for str2time()
#use Encode qw(encode decode encode_utf8 decode_utf8);
#use Time::HiRes qw(gettimeofday tv_interval);
#use Unicruft;

use DB_File;
use Fcntl;
use JSON;

use Pod::Usage;

use strict;

##------------------------------------------------------------------------------
## Constants & Globals
##------------------------------------------------------------------------------
our $prog = basename($0);
our ($help);

##-- vars: I/O
our $infile  = undef;  ##-- required
our $basename = undef; ##-- default: basename($infile)
our $outfile = "-";   ##-- default: stdout

our $keep_blanks = 0;  ##-- keep input whitespace?
our $format = 1;       ##-- output format level
our $foreign = 0;      ##-- relaxed (non-dta) mode?

##-- var: aux db
our $aux_dbfile = undef;    ##-- auxiliary db (Berkeley DB, ($basename => $metadata_json)
our $aux_xpath  = 'fileDesc[@n="ddc-aux"]';

##-- var: user XPaths
our %user_xpaths   = qw();  ##-- ($key => \@xpaths); known keys: date,author,...
our %user_defaults = qw();  ##-- default values (textClass*)

##-- constants: verbosity levels
our $vl_warn     = 1;
our $vl_progress = 2;
our $verbose = $vl_warn;

##-- constants: maximum field length (<=0 or undef for none)
our $max_bibl_len = 256;

##-- globals: XML parser
our $parser = XML::LibXML->new();
$parser->keep_blanks($keep_blanks ? 1 : 0);
$parser->line_numbers(1);

*isa = \&UNIVERSAL::isa;

##------------------------------------------------------------------------------
## Command-line
##------------------------------------------------------------------------------
GetOptions(##-- General
	   'help|h' => \$help,
	   'verbose|v=i' => \$verbose,
	   'quiet|q' => sub { $verbose=!$_[1]; },

	   ##-- General: behavior
	   'basename|base|b|dirname|dir|d=s' => \$basename,
	   'dta!' => sub { $foreign=!$_[1]; },
	   'foreign|extern!' => \$foreign,
	   'max-bibl-length|maxlen|l=i' => \$max_bibl_len,

	   ##-- auxiliary data
	   'aux-db|auxdb|adb|a=s' => \$aux_dbfile,
	   'aux-xpath|aux-xp|auxpath|axp|ap=s' => \$aux_xpath,

	   ##-- user-specified XPaths
	   'user-xpath|user-xp|userpath|uxp|xpath|xp=s%' => sub { push(@{$user_xpaths{$_[1]}},$_[2]); },
	   'user-default|ud|default|D=s%' => \%user_defaults,

	   ##-- I/O
	   'keep-blanks|blanks|whitespace|ws!' => \$keep_blanks,
	   'output|out|o=s' => \$outfile,
	   'format|fmt!' => \$format,
	  );

pod2usage({-exitval=>0,-verbose=>0}) if ($help);

##-- command-line: arguments
$infile = shift;
$infile = '-' if (!$infile);

##======================================================================
## Subs: t-xml stuff (*.t.xml)

## $xmldoc = loadxml($xmlfile)
##  + loads and returns xml doc
sub loadxml {
  my $xmlfile = shift;
  my $xdoc = $xmlfile eq '-' ? $parser->parse_fh(\*STDIN) : $parser->parse_file($xmlfile);
  die("$prog: ERROR: could not parse XML file '$xmlfile': $!") if (!$xdoc);
  return $xdoc;
}

##======================================================================
## X-Path utilities: user-specified

## @xpaths = user_xpaths($key)
sub user_xpaths {
  return @{ $user_xpaths{$_[0]} // [] };
}


##======================================================================
## X-Path utilities: get

## \@nods = xpnods($root, $xpath)
sub xpnods {
  my ($root,$xp) = @_;
  return undef if (!ref($root));
  return $root->findnodes($xp);
}

## $nod = xpnod($root, $xpath)
sub xpnod {
  my ($root,$xp) = @_;
  return undef if (!ref($root));
  return $root->findnodes($xp)->[0];
}

## $val = xpval($root, $xpath)
sub xpval {
  my $nod = xpnod(@_);
  return undef if (!defined($nod));
  return isa($nod,'XML::LibXML::Attribute') ? $nod->nodeValue : $nod->textContent;
}

## $nod = xpgrepnod($root,@xpaths)
##  + returns 1st defined node for @xpaths
sub xpgrepnod {
  my $root = shift;
  my ($xp,$nod);
  foreach $xp (@_) {
    return $nod if (defined($nod = xpnod($root,$xp)));
  }
  return undef;
}

## $val = xpgrepval($root,@xpaths)
##  + returns 1st defined value for @xpaths
sub xpgrepval {
  my $root = shift;
  my ($xp,$val);
  foreach $xp (@_) {
    return $val if (defined($val = xpval($root,$xp)));
  }
  return undef;
}

##======================================================================
## X-Path utilities: ensure

## \@xpspec = parse_xpath($xpath)
##  + handles basic xpaths only (/ELT or /ELT[@ATTR="VAL"])
sub parse_xpath {
  my $path = shift;
  return [
	  map {m/^([^\[\s]+)\[\s*\@([^\=\s]+)\s*=\s*\"([^\"\s]*)\"\s*\]/ ? [$1,$2=>$3] : $_}
	  grep {defined($_) && $_ ne ''}
	  split(/\//, $path)
	 ];
}

## $xpath_str = unparse_xpath(\@xpspec)
sub unparse_xpath {
  my ($elt,%attrs);
  return $_[0] if (!ref($_[0]));
  return join('/',
	      map {
		($elt,%attrs) = UNIVERSAL::isa($_,'ARRAY') ? (@$_) : ($_);
		"$elt\[".join(' and ', map {"\$_=\"$attrs{$_}\""} sort keys %attrs)."]"
	      } @{$_[0]});
}

## $node          = get_xpath($root,\@xpspec_or_xpath)      ##-- scalar context
## ($node,$isnew) = get_xpath($root,\@xpspec_or_xpath)      ##-- array context
##  + gets or creates node corresponding to \@xpspec_or_xpath
##  + each \@xpspec element is either
##    - a SCALAR ($tagname), or
##    - an ARRAY [$tagname, %attrs ]
sub get_xpath {
  my ($root,$xpspec) = @_;
  $xpspec = parse_xpath($xpspec) if (!ref($xpspec));
  my ($step,$xp,$tag,%attrs,$next);
  my $isnew = 0;
  foreach $step (@$xpspec) {
    ($tag,%attrs) = ref($step) ? @$step : ($step);
    $xp = $tag;
    $xp .= "[".join(' and ', map {"\@$_='$attrs{$_}'"} sort keys %attrs)."]" if (%attrs);
    if (!defined($next = $root->findnodes($xp)->[0])) {
      $next = $root->addNewChild(undef,$tag);
      $next->setAttribute($_,$attrs{$_}) foreach (sort keys %attrs);
      $isnew = 1;
    }
    $root = $next;
  }
  return wantarray ? ($root,$isnew) : $root;
}

## $nod = ensure_xpath($root,\@xpspec,$default_value)
## $nod = ensure_xpath($root,\@xpspec,$default_value,$warn_if_missing)
sub ensure_xpath {
  my ($root,$xpspec,$val,$warn_if_missing) = @_;
  my ($elt,$isnew) = get_xpath($root, $xpspec);
  if ($isnew) {
    warn("$prog: $basename: WARNING: missing XPath ".unparse_xpath($xpspec)." defaults to \"".($val||'')."\"")
      if ($warn_if_missing && $verbose >= $vl_warn);
    $elt->appendText($val) if (defined($val));
    $elt->parentNode->insertAfter(XML::LibXML::Comment->new("/".$elt->nodeName.": added by $prog"), $elt);
  }
  if (($max_bibl_len//0) > 0 && length($val//'') >= $max_bibl_len) {
    warn("$prog: $basename: WARNING: trimming XPath ".unparse_xpath($xpspec)." to max_bibl_len=$max_bibl_len characters")
      if ($verbose >= $vl_warn);

    my $oldelt = $elt;
    my $newelt = $elt = $oldelt->cloneNode(0);
    $oldelt->setNodeName($oldelt->nodeName . "_dtatw_orig");
    $oldelt->parentNode->insertAfter($newelt,$oldelt);
    my $newval = substr($val,0,($max_bibl_len > 3 ? ($max_bibl_len-3) : $max_bibl_len))."...";
    $newelt->appendText($newval);
    $newelt->parentNode->insertAfter(XML::LibXML::Comment->new("/".$newelt->nodeName.": trimmed by $prog"), $newelt);
  }
  return $elt;
}

##======================================================================
## string utils: normalize

sub normalize_space {
  my $s = shift;
  $s =~ s/\s+/ /sg;
  $s =~ s/^\s+//;
  $s =~ s/\s+$//;
  return $s;
}
BEGIN { *wsnorm = \&normalize_space; }


##======================================================================
## MAIN

##-- default: basename
if (!defined($basename)) {
  $basename = basename($infile);
  $basename =~ s/\..*$// if (!$foreign); ##-- auto-trim dta basenames
}
$basename =~ s{^\./}{};
$basename =~ s/\..*$// if (!$foreign); ##-- auto-trim dta basenames

##-- maybe open aux db
my %auxdb;
if ($aux_xpath && defined($aux_dbfile)) {
  tie(%auxdb, 'DB_File', $aux_dbfile, O_RDONLY, (0666&~umask), $DB_BTREE)
    or die("$prog: $infile ($basename): failed to tie aux-db file $aux_dbfile: $!");
}

##-- grab header file
my $hdoc = loadxml($infile);
my $hroot = $hdoc->documentElement;
if ($hroot->nodeName ne 'teiHeader') {
  die("$prog: $infile ($basename): ERROR: no //teiHeader element found")
    if (!defined($hroot=$hroot->findnodes('(//teiHeader)[1]')->[0]));
}

##-- meta: author
my @author_xpaths = (
		     'fileDesc/titleStmt/author[@n="ddc"]',							##-- new (formatted)
		     'fileDesc/titleStmt/author',								##-- new (direct, un-formatted)
		     'fileDesc/sourceDesc/biblFull/titleStmt/author',						##-- new (sourceDesc, un-formatted)
		     'fileDesc/titleStmt/editor[string(@corresp)!="#DTACorpusPublisher"]',   			##-- new (direct, un-formatted)
		     'fileDesc/sourceDesc/biblFull/titleStmt/editor[string(@corresp)!="#DTACorpusPublisher"]',	##-- new (sourceDesc, un-formatted)
		     'fileDesc/sourceDesc/listPerson[@type="searchNames"]/person/persName',			##-- old
		     './/idno[@type="author"]',									##-- flat fallback
		    );
my $author_nod = xpgrepnod($hroot,user_xpaths('author'),@author_xpaths);
my ($author);
if ($author_nod && $author_nod->nodeName eq 'persName') {
  ##-- parse pre-formatted author node (old, pre-2012-07)
  $author = $author_nod->textContent;
  warn("$prog: $basename: WARNING: using obsolete author node ", $author_nod->nodePath);
}
elsif ($author_nod && $author_nod->nodeName eq 'author' && ($author_nod->getAttribute('n')||'') eq 'ddc') {
  ##-- ddc-author node: direct from document
  $author = $author_nod->textContent;
}
elsif ($author_nod && $author_nod->nodeName eq 'idno') {
  ##-- fallback author node: direct from document
  $author = $author_nod->textContent;
}
elsif ($author_nod && $author_nod->nodeName =~ /^(?:author|editor)$/ && ($author_nod->getAttribute('n')||'') ne 'ddc') {
  warn("$prog: $basename: WARNING: formatting author node from ", $author_nod->nodePath) if ($verbose >= $vl_progress);
  ##-- parse structured author node (new, 2012-07)
  my ($nnods,$first,$last,$gen,@other,$name);
  $author = join('; ',
		 map {
		   $last  = xpval($_,'surname');
		   $first = xpval($_,'forename');
		   $gen   = xpval($_,'genName');
		   @other = (
			     (map {$_->textContent} @{$_->findnodes('addName')}), #|roleName e.g. "König von Preußen" beim alten Fritz (http://d-nb.info/gnd/118535749)
			     ($_->hasAttribute('ref') ? $_->getAttribute('ref') : qw()),
			     ($_->nodeName eq 'editor' || $_->parentNode->nodeName eq 'editor' ? 'ed.' : qw()),
			    );
		   $_ =~ s{^http://d-nb.info/gnd/}{#}g foreach (@other); ##-- pnd hack
		   $name = ($last||'').", ".($first||'').($gen ? " $gen" : '').' ('.join('; ', @other).')';
		   $name =~ s/^, //;
		   $name =~ s/ \(\)//;
		   $name
		 }
		 map {
		   $nnods = $_->findnodes('name|persName');
		   ($nnods && @$nnods ? @$nnods : $_)
		 }
		 @{$author_nod->findnodes('../'.$author_nod->nodeName.'[string(@corresp)!="#DTACorpusPublisher"]')});

  if (($author//'') eq '') {
    ##-- fallback: use literal text content
    $author = $author_nod->textContent;
  }
}
if (!defined($author)) {
  ##-- guess author from basename
  warn("$prog: $basename: WARNING: missing author XPath(s) ", join('|', @author_xpaths)) if (!$foreign && $verbose >= $vl_warn);
  $author = ($basename =~ m/^([^_]+)_/ ? $1 : '');
  $author =~ s/\b([[:lower:]])/\U$1/g; ##-- implicitly upper-case
}
ensure_xpath($hroot, 'fileDesc/titleStmt/author[@n="ddc"]', wsnorm($author));

##-- meta: title
my $title           = $foreign ? '' : ($basename =~ m/^[^_]+_([^_]+)_/ ? ucfirst($1) : '');
my $dta_title_xpath = 'fileDesc/titleStmt/title[@type="main" or @type="sub" or @type="vol"]';
my $dta_title_nods  = user_xpaths('title') ? [] : $hroot->findnodes($dta_title_xpath);
my @other_title_xpaths = (
			  'fileDesc/titleStmt/title[@type="ddc"]',
			  'fileDesc/titleStmt/title[not(@type)]',
			  'sourceDesc[@id="orig"]/biblFull/titleStmt/title',
			  'sourceDesc[@id="scan"]/biblFull/titleStmt/title',
			  'sourceDesc[not(@id)]/biblFull/titleStmt/title',
			  './/idno[@type="title"][last()]', ##-- flat fallback
			 );
my $other_title_nod  = xpgrepnod($hroot,user_xpaths('title'),@other_title_xpaths);
if (@$dta_title_nods) {
  $title  = join(' / ', map {$_->textContent} grep {$_->getAttribute('type') eq 'main'} @$dta_title_nods);
  $title .= join('', map {": ".$_->textContent} grep {$_->getAttribute('type') eq 'sub'} @$dta_title_nods);
  $title .= join('', map {" (".($_->textContent =~ m/\S/ ? $_->textContent : ($_->getAttribute('n')||'?')).")"} grep {$_->getAttribute('type') eq 'vol'} @$dta_title_nods);
}
elsif ($other_title_nod) {
  $title = $other_title_nod->textContent();
}
else {
  warn("$prog: $basename: WARNING: missing title XPath(s) $other_title_xpaths[0] defaults to '$title'") if (!$foreign && $verbose >= $vl_warn);
}
ensure_xpath($hroot, $other_title_xpaths[0], wsnorm($title), 0);

##-- meta: date (published)
my @date_xpaths = (
		   'fileDesc/sourceDesc[@n="ddc"]/biblFull/publicationStmt/date[@type="pub"]', ##-- ddc
		   'fileDesc/sourceDesc[@n="scan"]/biblFull/publicationStmt/date', ##-- old:publDate
		   'fileDesc/sourceDesc/biblFull/publicationStmt/date[@type="creation"]/supplied',
		   'fileDesc/sourceDesc/biblFull/publicationStmt/date[@type="creation"]',
		   'fileDesc/sourceDesc/biblFull/publicationStmt/date[@type="publication"]/supplied', ##-- new:date (published, supplied)
		   'fileDesc/sourceDesc/biblFull/publicationStmt/date[@type="publication"]', ##-- new:date (published)
		   'fileDesc/sourceDesc/biblFull/publicationStmt/date/supplied', ##-- new:date (generic, supplied)
		   'fileDesc/sourceDesc/biblFull/publicationStmt/date', ##-- new:date (generic, supplied)
		   './/idno[@type="date"][last()]',			##-- flat fallback
		   './/idno[@type="year"][last()]',			##-- flat fallback
		  );
my $date = xpgrepval($hroot,user_xpaths('date'),@date_xpaths);
my $date0 = $date // '';
if (!$date) {
  $date = ($basename =~ m/^[^\.]*_([0-9]+)$/ ? $1 : 0);
  warn("$prog: $basename: WARNING: missing date XPath $date_xpaths[$#date_xpaths] defaults to \"$date\"") if ($verbose >= $vl_warn);
}
$date =~ s/(?:^\s*)|(?:\s*$)//g;
if ($date =~ s/^((?:um|circa|ca\.|~)\s*)//i) {
  warn("$prog: $basename: WARNING: trimming leading approximation prefix '$1' from parsed date '$date0'") if ($verbose >= $vl_warn);
}
if ($date =~ s/^([0-9\-]+)([^0-9\-]+)$/$1/) {
  warn("$prog: $basename: WARNING: trimming trailing non-numeric suffix '$2' from parsed date '$date0'") if ($verbose >= $vl_warn);
}
if ($date =~ /[^0-9\-]/) {
  warn("$prog: $basename: WARNING: trimming non-digits from parsed date '$date0'") if ($verbose >= $vl_warn);
  $date =~ s/[^0-9\-]//g;
}
#ensure_xpath($hroot, 'fileDesc/sourceDesc[@n="scan"]/biblFull/publicationStmt/date[@type="first"]', $date); ##-- old (<2012-07)
ensure_xpath($hroot, 'fileDesc/sourceDesc[@n="ddc"]/biblFull/publicationStmt/date[@type="pub"]', wsnorm($date));  ##-- new (>=2012-07)

##-- meta: date (first)
foreach (@date_xpaths) {
  s/="scan"/="orig"/;
  s/="publication"/="firstPublication"/;
  s/="pub"/="first"/;
}
my $date1 = xpgrepval($hroot,@date_xpaths);
if (!$date1) {
  $date1 = $date;
  warn("$prog: $basename: WARNING: missing original-date XPath $date_xpaths[$#date_xpaths] defaults to \"$date1\"") if (0 && $verbose >= $vl_warn);
}
#ensure_xpath($hroot, 'fileDesc/sourceDesc[@n="orig"]/biblFull/publicationStmt/date[@type="first"]', $date1); ##-- old (<2012-07)
ensure_xpath($hroot, 'fileDesc/sourceDesc[@n="ddc"]/biblFull/publicationStmt/date[@type="first"]', wsnorm($date1));  ##-- new (>=2012-11)

##-- meta: bibl
my @bibl_xpaths = (
		   'fileDesc/sourceDesc[@n="ddc"]/bibl', ##-- new:canonical
		   'fileDesc/sourceDesc[@n="orig"]/bibl', ##-- old:firstBibl
		   'fileDesc/sourceDesc[@n="scan"]/bibl', ##-- old:publBibl
		   'fileDesc/sourceDesc/bibl', ##-- new|old:generic
		   './/idno[@type="bibl"]',    ##-- flat fallback
		  );
#push(@{$user_xpaths{'bibl'}}, '"foo"');
my $bibl = xpgrepval($hroot,user_xpaths('bibl'),@bibl_xpaths);
if (!defined($bibl)) {
  $bibl = "$author: $title. $date0";
  warn("$prog: $basename: WARNING: missing bibl XPath(s) ".join('|',@bibl_xpaths)) if ($verbose >= $vl_warn);
}
ensure_xpath($hroot, 'fileDesc/sourceDesc[@n="orig"]/bibl', wsnorm($bibl)); ##-- old (<2012-07)
ensure_xpath($hroot, 'fileDesc/sourceDesc[@n="ddc"]/bibl', wsnorm($bibl)); ##-- new (>=2012-07)

##-- meta: shelfmark
my @shelfmark_xpaths = (
			'fileDesc/sourceDesc[@n="ddc"]/msDesc/msIdentifier/idno/idno[@type="shelfmark"]', ##-- new:canonical
			'fileDesc/sourceDesc[@n="ddc"]/msDesc/msIdentifier/idno[@type="shelfmark"]', ##-- -2013-08-04
			'fileDesc/sourceDesc/msDesc/msIdentifier/idno/idno[@type="shelfmark"]',
			'fileDesc/sourceDesc/msDesc/msIdentifier/idno[@type="shelfmark"]', ##-- new (>=2012-07)
			'fileDesc/sourceDesc/biblFull/notesStmt/note[@type="location"]/ident[@type="shelfmark"]', ##-- old (<2012-07)
		       );
my $shelfmark = xpgrepval($hroot,user_xpaths('shelfmark'),@shelfmark_xpaths) || '-';
ensure_xpath($hroot, $shelfmark_xpaths[0], wsnorm($shelfmark), 0);

##-- meta: library
my @library_xpaths = (
		      'fileDesc/sourceDesc[@n="ddc"]/msDesc/msIdentifier/repository', ##-- new:canonical
		      'fileDesc/sourceDesc/msDesc/msIdentifier/repository', ##-- new
		      'fileDesc/sourceDesc/biblFull/notesStmt/note[@type="location"]/name[@type="repository"]', ##-- old
		     );
my $library = xpgrepval($hroot, user_xpaths('library'), @library_xpaths) || '-';
ensure_xpath($hroot, $library_xpaths[0], wsnorm($library), 0);

##-- meta: dtadir
my @dirname_xpaths = (
		      'fileDesc/publicationStmt[@n="ddc"]/idno[@type="basename"]', ##-- new:canonical
		      'fileDesc/publicationStmt/idno/idno[@type="DTADirName"]', ##-- (>=2013-09-04)
		      'fileDesc/publicationStmt/idno[@type="DTADirName"]', ##-- (>=2013-09-04)
		      'fileDesc/publicationStmt/idno[@type="DTADIRNAME"]', ##-- new (>=2012-07)
		      'fileDesc/publicationStmt/idno[@type="DTADIR"]',     ##-- old (<2012-07)
		     );
my $dirname = xpgrepval($hroot,user_xpaths('dirname'),@dirname_xpaths) || $basename;
ensure_xpath($hroot, $dirname_xpaths[0], wsnorm($dirname), 0);
ensure_xpath($hroot, $dirname_xpaths[1], wsnorm($dirname), 1) if (!$foreign); ##-- dta compat

##-- meta: dtaid
my @dtaid_xpaths = (
		    'fileDesc/publicationStmt[@n="ddc"]/idno[@type="dtaid"]', ##-- new:canonical
		    'fileDesc/publicationStmt/idno/idno[@type="DTAID"]',
		    'fileDesc/publicationStmt/idno[@type="DTAID"]',
		   );
my $dtaid = xpgrepval($hroot,user_xpaths('dtaid'),@dtaid_xpaths) || "0";
ensure_xpath($hroot, $dtaid_xpaths[0], wsnorm($dtaid), 0);
ensure_xpath($hroot, $dtaid_xpaths[1], wsnorm($dtaid), 1) if (!$foreign); ##-- dta compat

##-- meta: timestamp: ISO
my @timestamp_xpaths = (
			'fileDesc/publicationStmt/date[@type="ddc-timestamp"]',
			($foreign ? qw() : 'fileDesc/publicationStmt/date'),
		       );
my $timestamp = xpgrepval($hroot, user_xpaths('timestamp'), @timestamp_xpaths);
if (!$timestamp) {
  my $time = $infile eq '-' ? time() : (stat($infile))[9];
  $timestamp = POSIX::strftime("%FT%H:%M:%SZ",gmtime($time));
}
ensure_xpath($hroot, $timestamp_xpaths[0], wsnorm($timestamp), 0);

##-- meta: availability (text)
my @availability_xpaths = (
			   'fileDesc/publicationStmt/availability[@type="ddc"]',
			   'fileDesc/publicationStmt/availability',
			  );
my $availability        = xpgrepval($hroot,user_xpaths('availability'), @availability_xpaths) || "-";
ensure_xpath($hroot, $availability_xpaths[0], wsnorm($availability), 0);

##-- meta: availability (dwds code: "OR0W".."MR3S" ~ "ohne-rechte-0-wörter".."mit-rechten-3-sätze")
my @avail_xpaths = (
		    'fileDesc/publicationStmt/availability[@type="ddc_dwds"]',
		    'fileDesc/publicationStmt/availability/@n',
		   );
my $avail       = xpgrepval($hroot,user_xpaths('avail'),@avail_xpaths) || "-";
ensure_xpath($hroot, $avail_xpaths[0], wsnorm($avail), 0);

##-- meta: text-class: dta
my @uxp_tcdta = user_xpaths('textClassDTA');
my $tcdta = join('::',
		 map {normalize_space($_->textContent)}
		 @{xpnods($hroot,join('|',
				      (@uxp_tcdta ? @uxp_tcdta
				       : (
					  'profileDesc/textClass/classCode[@scheme="https://www.deutschestextarchiv.de/doku/klassifikation#dtamain"]',
					  'profileDesc/textClass/classCode[@scheme="https://www.deutschestextarchiv.de/doku/klassifikation#dtasub"]',
					  ##
					  'profileDesc/textClass/classCode[@scheme="http://www.deutschestextarchiv.de/doku/klassifikation#dtamain"]',
					  'profileDesc/textClass/classCode[@scheme="http://www.deutschestextarchiv.de/doku/klassifikation#dtasub"]',
					 ))
				     ))}
		);
ensure_xpath($hroot, 'profileDesc/textClass/classCode[@scheme="ddcTextClassDTA"]', wsnorm($tcdta||$user_defaults{'textClassDTA'}||''), 0);

##-- meta: text-class: dwds
my @uxp_tcdwds = user_xpaths('textClassDWDS');
my $tcdwds = join('::',
		  map {normalize_space($_->textContent)}
		  @{xpnods($hroot,join('|',
				       (@uxp_tcdwds ? @uxp_tcdwds
					: (
					   'profileDesc/textClass/classCode[@scheme="https://www.deutschestextarchiv.de/doku/klassifikation#dwds1main"]',
					   'profileDesc/textClass/classCode[@scheme="https://www.deutschestextarchiv.de/doku/klassifikation#dwds1sub"]',
					   'profileDesc/textClass/classCode[@scheme="https://www.deutschestextarchiv.de/doku/klassifikation#dwds2main"]',
					   'profileDesc/textClass/classCode[@scheme="https://www.deutschestextarchiv.de/doku/klassifikation#dwds2sub"]',
					   ##
					   'profileDesc/textClass/classCode[@scheme="http://www.deutschestextarchiv.de/doku/klassifikation#dwds1main"]',
					   'profileDesc/textClass/classCode[@scheme="http://www.deutschestextarchiv.de/doku/klassifikation#dwds1sub"]',
					   'profileDesc/textClass/classCode[@scheme="http://www.deutschestextarchiv.de/doku/klassifikation#dwds2main"]',
					   'profileDesc/textClass/classCode[@scheme="http://www.deutschestextarchiv.de/doku/klassifikation#dwds2sub"]',
					   ##
					   'profileDesc/textClass/keywords/term', ##-- dwds keywords
					  ))
				      ))}
		 );
ensure_xpath($hroot, 'profileDesc/textClass/classCode[@scheme="ddcTextClassDWDS"]', wsnorm($tcdwds||$user_defaults{'textClassDWDS'}||''), 0);

##-- meta: text-class: dta-corpus (ocr|mts|cn|...)
my @uxp_corpus = user_xpaths('textClassCorpus');
my $tccorpus = join('::',
		    map {normalize_space($_->textContent)}
		    @{xpnods($hroot,join('|',
					 (@uxp_corpus ? @uxp_corpus
					  : (
					     'profileDesc/textClass/classCode[@scheme="https://www.deutschestextarchiv.de/doku/klassifikation#DTACorpus"]',
					     'profileDesc/textClass/classCode[@scheme="http://www.deutschestextarchiv.de/doku/klassifikation#DTACorpus"]',
					    ))
					))}
		   );
ensure_xpath($hroot, 'profileDesc/textClass/classCode[@scheme="ddcTextClassCorpus"]', wsnorm($tccorpus||$user_defaults{'textClassCorpus'}||''), 0);

##-- apply aux-db
my ($aux_buf);
if ( $aux_xpath && ($aux_buf = $auxdb{$basename}) ) {
  my $meta = from_json($aux_buf, {utf8=>!utf8::is_utf8($aux_buf), relaxed=>1, allow_nonref=>1, allow_unknown=>1})
    or die("$prog: $basename: ERROR: failed to parse aux-db JSON metatdata '$aux_buf'");
  die("$prog: $basename: ERROR: JSON metadata is not a HASH-ref") if (!UNIVERSAL::isa($meta,'HASH'));

  my $auxnod = ensure_xpath($hroot, $aux_xpath, undef,0);
  my ($key,$val,$nod);
  while (($key,$val)=each(%$meta)) {
    $nod = $auxnod->addNewChild(undef, 'idno');
    $nod->setAttribute('type'=>$key);
    $nod->appendText($val);
  }
}

##-- dump
($outfile eq '-' ? $hdoc->toFH(\*STDOUT,$format) : $hdoc->toFile($outfile,$format))
  or die("$prog: ERROR: failed to write output file '$outfile': $!");


__END__

=pod

=head1 NAME

dtatw-sanitize-header.perl - make DDC/DTA-friendly TEI-headers

=head1 SYNOPSIS

 dtatw-sanitize-header.perl [OPTIONS] XML_HEADER_FILE

 General Options:
  -help                  # this help message
  -verbose LEVEL         # set verbosity level (0<=LEVEL<=1)
  -quiet                 # alias for -verbose=0
  -dta , -foreign        # do/don't warn about strict DTA header compliance (default=do)
  -max-bibl-length LEN   # trim bibl fields to maximum length LEN (default=256)

 Auxiliary DB Options:   # optional BASENAME-keyed JSON-metadata Berkeley DB
  -aux-db DBFILE         # read auxiliary DB from DBFILE (default=none)
  -aux-xpath XPATH       # append <idno type="KEY"> elements to XPATH (default='fileDesc[@n="ddc-aux"]')

 XPath Options:
  -xpath ATTR=XPATH      # prepend XPATH for attribute ATTR
  -default ATTR=VAL      # default values (for textClass* attributes)

 I/O Options:
  -blanks , -noblanks    # do/don't keep 'ignorable' whitespace in XML_HEADER_FILE file (default=don't)
  -base BASENAME	 # use BASENAME to auto-compute field names (default=basename(XML_HEADER_FILE))
  -output FILE           # specify output file (default='-' (STDOUT))

=cut

##------------------------------------------------------------------------------
## Options and Arguments
##------------------------------------------------------------------------------
=pod

=head1 OPTIONS AND ARGUMENTS

=cut

##----------------------------------------------------------------------
## General Options
=pod

=head2 General Options

=over 4

=item -h, -help

Display a brief usage summary and exit.

=item -v, -verbose LEVEL

Set verbosity level; values for I<LEVEL> are:

 0: silent
 1: warnings only
 2: warnings and progress messages

=item -q, -quiet

Alis for -verbose=0

=item -b, -basename BASENAME

Set basename for generated header fields; default is
the basename (non-directory portion) of I<XML_HEADER_FILE>
up to but not including the first dot (".") character, if any.
In default C<-dta> mode, everything after the first dot character
in I<BASENAME> will be truncated even if you specify this option;
in C<-foreign> mode, dots in basenames passed in via this option are allowed.

=item -dta, -nodta

Do/don't run with DTA-specific heuristics and attempt to enforce DTA-header compliance (default: do).

=item -foreign

Alias for C<-nodta>.

=item -l, -max-bibl-len LEN

Trim sanitized XPaths to maximum length LEN characters (default=256).

=back

=cut

##----------------------------------------------------------------------
## Auxiliary DB Options
=pod

=head2 Auxiliary DB Options

You can optionally use a I<BASENAME>-keyed JSON-metadata Berkeley DB file
to automatically insert additional metadata fields into an existing header.

=over 4

=item -aux-db DBFILE

Apply auxiliary metadata from Berkeley DB file I<DBFILE> (default=none).
Keys of I<DBFILE> should be I<BASENAME>s as parsed from I<XML_HEADER_FILE>
or passed in via the C<-basename> option, and the associated values should be
flat JSON objects whose keys are the names of metadata attributes for I<BASENAME>
and whose values are the values of those metadata attributes.

=item -aux-xpath XPATH

Append C<E<lt>idno type="I<KEY>"E<gt>I<VAL>E<lt>/idnoE<gt>> elements to I<XPATH> (default=C<'fileDesc[@n="ddc-aux"]'>)
for auxiliary metadata attributes.

=back

=cut

##----------------------------------------------------------------------
## XPath Options
=pod

=head2 XPath Options

You can optionally specify source XPaths to override the defaults with
the C<-xpath> option.

=over 4

=item -xpath ATTR=XPATH

Prepend I<XPATH> to the builtin list of source XPaths for the attribute I<ATTR>.
Known attributes:
author title date bibl shelfmark library dirname dtaid timestamp
availability avail textClassDTA textClassDWDS textClassCorpus.

=item -default ATTR=VALUE

Default value for attribute ATTR.  Only used for textClass* attributes.

=back

=cut

##----------------------------------------------------------------------
## I/O Options
=pod

=head2 I/O Options

=over 4

=item -[no]keep-blanks

Do/don't retain all whitespace in input file (default=don't).

=item -o, -output OUTFILE

Write output to I<OUTFILE>; default="-" (standard output).

=item -format LEVEL

Format output at libxml level I<LEVEL> (default=1).

=back

=cut

##------------------------------------------------------------------------------
## Description
##------------------------------------------------------------------------------
=pod

=head1 DESCRIPTION

dtatw-sanitize-header.perl applies some parsing and encoding heuristics to a TEI-XML header
file I<XML_HEADER_FILE> in an attempt to ensure compliance with DTA/D* header conventions for subsequent
DDC indexing.  For each supported metadata attribute, a corresponding header record
is first sought by means of a first-match-wins XPath list.  If no existing header record is found,
a default (possibly empty) value is heuristically assigned, and the resulting value is inserted
into the header at a conventional XPath location.

The metadata attributes currently supported are listed below;
Source XPaths in the list are specified relative to the
root C<E<lt>teiHeaderE<gt>> element, and unless otherwise noted,
the first source XPath listed is also the target XPath,
guaranteed to be exist in the output header on successful script completion.

See L<https://kaskade.dwds.de/dstar/doc/README.html#bibliographic_metadata_attributes>
for details on D* metadata attribute conventions.

=head2 author

XPath(s):

 fileDesc/titleStmt/author[@n="ddc"]							##-- ddc: canonical target (formatted)
 fileDesc/titleStmt/author								##-- new (direct, un-formatted)
 fileDesc/sourceDesc/biblFull/titleStmt/author						##-- new (sourceDesc, un-formatted)
 fileDesc/titleStmt/editor[string(@corresp)!="#DTACorpusPublisher"]   			##-- new (direct, un-formatted)
 fileDesc/sourceDesc/biblFull/titleStmt/editor[string(@corresp)!="#DTACorpusPublisher"]	##-- new (sourceDesc, un-formatted)
 fileDesc/sourceDesc/listPerson[@type="searchNames"]/person/persName			##-- old

Heuristically parses and formats C<persName>, C<surname>, C<forename>, and C<genName> elements to a human-readable string.
In DTA mode, defaults to the first component of the "_"-separated I<BASENAME>.

=head2 title

XPath(s):

 fileDesc/titleStmt/title[@type="main" or @type="sub" or @type="vol"]	##-- DTA-mode only
 fileDesc/titleStmt/title[@type="ddc"]					##-- ddc: canonical target (formatted)
 fileDesc/titleStmt/title[not(@type)]
 sourceDesc[@id="orig"]/biblFull/titleStmt/title
 sourceDesc[@id="scan"]/biblFull/titleStmt/title
 sourceDesc[not(@id)]/biblFull/titleStmt/title

In DTA mode, heuristically parses and formats C<@type="main">, C<@type="sub">, C<@type="vol"> elements to a human-readable string,
and defaults to the second component of the "_"-separated I<BASENAME>.

=head2 date

XPath(s):

 fileDesc/sourceDesc[@n="ddc"]/biblFull/publicationStmt/date[@type="pub"]		##-- ddc: canonical target
 fileDesc/sourceDesc[@n="scan"]/biblFull/publicationStmt/date				##-- old:publDate
 fileDesc/sourceDesc/biblFull/publicationStmt/date[@type="creation"]/supplied
 fileDesc/sourceDesc/biblFull/publicationStmt/date[@type="creation"]
 fileDesc/sourceDesc/biblFull/publicationStmt/date[@type="publication"]/supplied	##-- new:date (published, supplied)
 fileDesc/sourceDesc/biblFull/publicationStmt/date[@type="publication"]			##-- new:date (published)
 fileDesc/sourceDesc/biblFull/publicationStmt/date/supplied				##-- new:date (generic, supplied)
 fileDesc/sourceDesc/biblFull/publicationStmt/date					##-- new:date (generic, supplied)

Heuristically trims everything but digits and hyphens from the extracted date-string.
In DTA mode, defaults to the final component of the "_"-separated I<BASENAME>.

=head2 firstDate

XPath(s):

 fileDesc/sourceDesc[@n="ddc"]/biblFull/publicationStmt/date[@type="first"]		##-- ddc: canonical target
 fileDesc/sourceDesc[@n="orig"]/biblFull/publicationStmt/date				##-- old: publDate
 fileDesc/sourceDesc/biblFull/publicationStmt/date[@type="creation"]/supplied
 fileDesc/sourceDesc/biblFull/publicationStmt/date[@type="creation"]
 fileDesc/sourceDesc/biblFull/publicationStmt/date[@type="firstPublication"]/supplied	##-- new:date (first, supplied)
 fileDesc/sourceDesc/biblFull/publicationStmt/date[@type="firstPublication"]		##-- new:date (first)
 fileDesc/sourceDesc/biblFull/publicationStmt/date/supplied				##-- new:date (generic, supplied)
 fileDesc/sourceDesc/biblFull/publicationStmt/date					##-- new:date (generic, supplied)

Heuristically trims everything but digits and hyphens from the extracted date-string.
Defaults to the publication date (see above).

=head2 bibl

XPath(s):

 fileDesc/sourceDesc[@n="ddc"]/bibl	##-- ddc:canonical target
 fileDesc/sourceDesc[@n="orig"]/bibl	##-- old:firstBibl, target
 fileDesc/sourceDesc[@n="scan"]/bibl	##-- old:publBibl
 fileDesc/sourceDesc/bibl		##-- new|old:generic

Heuristically generated from I<author>, I<title>, and I<date> if not set.
Ensures that the first 2 XPaths are set in the output file.

=head2 shelfmark

XPath(s):

 fileDesc/sourceDesc[@n="ddc"]/msDesc/msIdentifier/idno/idno[@type="shelfmark"] 	##-- ddc: canonical target
 fileDesc/sourceDesc[@n="ddc"]/msDesc/msIdentifier/idno[@type="shelfmark"]		##-- -2013-08-04
 fileDesc/sourceDesc/msDesc/msIdentifier/idno/idno[@type="shelfmark"]
 fileDesc/sourceDesc/msDesc/msIdentifier/idno[@type="shelfmark"]			##-- new (>=2012-07)
 fileDesc/sourceDesc/biblFull/notesStmt/note[@type="location"]/ident[@type="shelfmark"]	##-- old (<2012-07)

=head2 library

XPath(s):

 fileDesc/sourceDesc[@n="ddc"]/msDesc/msIdentifier/repository				##-- ddc: canonical target
 fileDesc/sourceDesc/msDesc/msIdentifier/repository					##-- new
 fileDesc/sourceDesc/biblFull/notesStmt/note[@type="location"]/name[@type="repository"] ##-- old

=head2 basename (dtadir)

XPath(s):

 fileDesc/publicationStmt[@n="ddc"]/idno[@type="basename"]	##-- new: canonical target
 fileDesc/publicationStmt/idno/idno[@type="DTADirName"]		##-- (>=2013-09-04)
 fileDesc/publicationStmt/idno[@type="DTADirName"]		##-- (>=2013-09-04)
 fileDesc/publicationStmt/idno[@type="DTADIRNAME"]		##-- new (>=2012-07)
 fileDesc/publicationStmt/idno[@type="DTADIR"]			##-- old (<2012-07)

Heuristically set to I<BASENAME> if not found.

=head2 dtaid

XPath(s):

 fileDesc/publicationStmt[@n="ddc"]/idno[@type="dtaid"]		##-- ddc: canonical target
 fileDesc/publicationStmt/idno/idno[@type="DTAID"]
 fileDesc/publicationStmt/idno[@type="DTAID"]

Defaults to "0" (zero) if unset.

=head2 timestamp

XPath(s):

 fileDesc/publicationStmt/date[@type="ddc-timestamp"]		##-- ddc: canonical target
 fileDesc/publicationStmt/date					##-- DTA mode only

Defaults to last modification time of I<XML_HEADER_FILE> or the current time
if not set.

=head2 availability (human-readable)

XPath(s):

 fileDesc/publicationStmt/availability[@type="ddc"]
 fileDesc/publicationStmt/availability

Defaults to "-" if unset.

=head2 avail (DWDS code)

XPath(s):

 fileDesc/publicationStmt/availability[@type="ddc_dwds"]
 fileDesc/publicationStmt/availability/@n

Defaults to "-" if unset.

=head2 textClass

Source XPath(s):

 profileDesc/textClass/classCode[@scheme="https://www.deutschestextarchiv.de/doku/klassifikation#dwds1main"]
 profileDesc/textClass/classCode[@scheme="https://www.deutschestextarchiv.de/doku/klassifikation#dwds1sub"]
 profileDesc/textClass/classCode[@scheme="https://www.deutschestextarchiv.de/doku/klassifikation#dwds2main"]
 profileDesc/textClass/classCode[@scheme="https://www.deutschestextarchiv.de/doku/klassifikation#dwds2sub"]
 profileDesc/textClass/classCode[@scheme="http://www.deutschestextarchiv.de/doku/klassifikation#dwds1main"]
 profileDesc/textClass/classCode[@scheme="http://www.deutschestextarchiv.de/doku/klassifikation#dwds1sub"]
 profileDesc/textClass/classCode[@scheme="http://www.deutschestextarchiv.de/doku/klassifikation#dwds2main"]
 profileDesc/textClass/classCode[@scheme="http://www.deutschestextarchiv.de/doku/klassifikation#dwds2sub"]
 profileDesc/textClass/keywords/term ##-- dwds keywords

Target XPath:

 profileDesc/textClass/classCode[@scheme="ddcTextClassDWDS"]


=head2 textClassDTA

Source XPath(s):

 profileDesc/textClass/classCode[@scheme="https://www.deutschestextarchiv.de/doku/klassifikation#dtamain"]
 profileDesc/textClass/classCode[@scheme="https://www.deutschestextarchiv.de/doku/klassifikation#dtasub"]
 profileDesc/textClass/classCode[@scheme="http://www.deutschestextarchiv.de/doku/klassifikation#dtamain"]
 profileDesc/textClass/classCode[@scheme="http://www.deutschestextarchiv.de/doku/klassifikation#dtasub"]

Target XPath:

 profileDesc/textClass/classCode[@scheme="ddcTextClassDTA"]

=head2 DTA corpus

Source XPath(s):

 profileDesc/textClass/classCode[@scheme="https://www.deutschestextarchiv.de/doku/klassifikation#DTACorpus"]
 profileDesc/textClass/classCode[@scheme="http://www.deutschestextarchiv.de/doku/klassifikation#DTACorpus"]

Target XPath:

 profileDesc/textClass/classCode[@scheme="ddcTextClassCorpus"]

=cut

##------------------------------------------------------------------------------
## See Also
##------------------------------------------------------------------------------
=pod

=head1 SEE ALSO

L<dtatw-get-header.perl(1)|dtatw-get-header.perl>,
...

=cut

##------------------------------------------------------------------------------
## Footer
##------------------------------------------------------------------------------
=pod

=head1 AUTHOR

Bryan Jurish E<lt>moocow@cpan.orgE<gt>

=cut
