#!/usr/bin/perl -w

use IO::File;
use XML::Parser;
use XML::LibXML;
use Getopt::Long qw(:config no_ignore_case);
use Encode qw(encode decode encode_utf8 decode_utf8);
use File::Basename qw(basename);
use Time::HiRes qw(gettimeofday tv_interval);
use Unicruft;
use Algorithm::BinarySearch::Vec qw(:default);
use Fcntl qw(SEEK_SET);
use Pod::Usage;

use lib qw(.);
use DTA::TokWrap::CxData qw(:all);

use strict;

##------------------------------------------------------------------------------
## Constants & Globals
##------------------------------------------------------------------------------
our $prog = basename($0);
our ($help);

##-- vars: I/O
our $txmlfile = undef; ##-- required
our $cxfile   = undef; ##-- default: ($txmlfile:.t.xml=.cx)
our $sxfile   = undef; ##-- default: ($cxfile:.cx=.sx)
our $outfile  = "-";   ##-- default: stdout
our $format = 1;       ##-- output format level

##-- constants (hacks)
our $PAGE_BOTTOM_Y = 50001;
our $PAGE_TOP_Y = 1;
our $MAX_FORMULA_PIX = 1024; ##-- any formula bboxes higher $MAX_FORMULA_PIX are chucked
our $MIN_FORMULA_PIX = 100;  ##-- formula bboxes shorter than $MIN_FORMULA_PIX are extended
our $NOKEY = $Algorithm::BinarySearch::Vec::KEY_NOT_FOUND;

##-- selection
our $keep_blanks = 0;  ##-- libxml parser attribute
our $do_ext_dtd = 0;   ##-- libxml parser option
our $keep_ws = 0;      ##-- whether to keep word text-internal whitespace
our $do_page = 1;
our $do_line = 1;
our $do_rendition = 1;
our $do_xcontext = 1;
our $do_xpath = 1;
our $do_xppath= 0;
our $do_bbox = 0;
our $do_unicruft = 1;
our $do_wsep = 1;

our $do_keep_c  = 1;
our $do_keep_b  = 1;
our $do_keep_xb = 1;

##-- output attributes
our $rendition_attr = 'xr';
our $xcontext_attr  = 'xc';
our $xpath_attr     = 'xp';
our $xppath_attr    = 'xpp';
our $page_attr      = 'pb';
our $line_attr      = 'lb';
our $bbox_attr      = 'bb';
our $unicruft_attr  = 'u';
our $coff_attr      = 'coff';
our $clen_attr      = 'clen';
our $boff_attr      = 'boff';
our $blen_attr      = 'blen';
our $wsep_attr	    = 'ws';
our $formula_text   = ''; ##-- output text for //formula elements (undef: no change)

##-- constants: verbosity levels
our $vl_warn     = 1;
our $vl_info     = 2;
our $vl_progress = 3;
our $verbose = $vl_progress;     ##-- print progress messages by default

##-- warnings: specific options
our $warn_on_empty_clist = 1;       ##-- warn on empty //c list for //w in txmlfile?
our $warn_on_empty_blist = 1;       ##-- warn on empty sx-block list for //w in txmlfile?
our $warn_on_bad_page   = 1;        ##-- warn on bad //w/@pb attribute?
our $warn_on_bad_facs   = 1;        ##-- warn on missing pb/@facs?
our $foreign = 0;		    ##-- "foreign" (non-dta) mode?
our %n_warnings = qw();

##------------------------------------------------------------------------------
## Command-line
##------------------------------------------------------------------------------
GetOptions(##-- General
	   'help|h' => \$help,
	   'verbose|v=i' => \$verbose,
	   'quiet|q' => sub { $verbose=!$_[1]; },

	   ##-- I/O
	   'cxfile|cxf|cx=s' => \$cxfile,
	   'sxfile|sxf|sx=s' => \$sxfile,
	   'keep-blanks|blanks!' => \$keep_blanks,
	   'external-dtd|ext-dtd|edtd|dtd!' => \$do_ext_dtd,
	   'output|out|o=s' => \$outfile,
	   'format|f!' => \$format,

	   ##-- behavior
	   'whitespace|ws!' => \$keep_ws,
	   'page|pb|p!' => \$do_page,
	   'line|lb|l!' => \$do_line,
	   'rendition|rend|xr|r!' => \$do_rendition,
	   'xcontext|context|xcon|con|xc!' => \$do_xcontext,
	   'xpath|path|xp!' => \$do_xpath,
	   'xppath|ppath|xpp!' => \$do_xppath,
	   'coordinates|coords|coord|c|bboxes|bbox|bb|b!' => \$do_bbox,
	   'unicruft|cruft|u|transliterate|xlit|xl!' => \$do_unicruft,
	   'word-separation|word-sep|wsep|sep!' => \$do_wsep,
	   'keep-c|keepc|kc!' => \$do_keep_c,
	   'keep-b|keepb|kb!' => \$do_keep_b,
	   'keep-xb|keepxb|kxb!' => \$do_keep_xb,
	   'formula-text|ft=s' => \$formula_text,
	   'foreign!' => sub { $warn_on_bad_facs=!$_[1]; $foreign=1; },
	   'dta!'     => sub { $warn_on_bad_facs=$_[1];  $foreign=0; },
	  );

pod2usage({-exitval=>0,-verbose=>0}) if ($help);

##-- command-line: arguments
$txmlfile = @ARGV ? shift : '-';
if (!defined($cxfile) || $cxfile eq '') {
  ($cxfile = $txmlfile) =~ s/\.t\.xml$/.cx/;
  pod2usage({-exitval=>0,-verbose=>0,-msg=>"$prog: could not guess CX_FILE for T_XML_FILE=$txmlfile"})
    if ($cxfile eq $txmlfile);
}
if (!defined($sxfile) || $sxfile eq '') {
  ($sxfile = $cxfile) =~ s/\.cx$/.sx/;
  pod2usage({-exitval=>0,-verbose=>0,-msg=>"$prog: could not guess SX_FILE for CX_FILE=$cxfile"})
    if ($sxfile eq $cxfile);
}
$prog  = "$prog: ".basename($txmlfile);

##-- sanity checks
$do_page = 1 if ($do_bbox);
$do_line = 1 if ($do_bbox);

##-- foreign-mode
our ($rend_left,$rend_right,$rend_sep) = ('|','|','|');
if ($foreign) {
  ($rend_left,$rend_right,$rend_sep) = ('','',':');
}

##======================================================================
## Subs: t-xml stuff (*.t.xml)

## $Ns,$Nw : number of (words|sentences) from .tx-file
##  + only set if $verbose >= $vl_info
our ($Ns,$Nw) = (0,0);

## $txmldoc = load_txml($txmlfile)
##  + loads and returns xml doc
sub load_txml {
  my $xmlfile = shift;

  ##-- initialize LibXML parser
  my $parser = XML::LibXML->new();
  $parser->keep_blanks($keep_blanks ? 1 : 0);
  $parser->line_numbers(1);
  $parser->load_ext_dtd($do_ext_dtd);

  ##-- load xml
  my $xdoc = $xmlfile eq '-' ? $parser->parse_fh(\*STDIN) : $parser->parse_file($xmlfile);
  die("$prog: FATAL: could not parse .t.xml file '$xmlfile': $!") if (!$xdoc);

  ##-- get stats
  if ($verbose >= $vl_info) {
    $Ns = scalar(@{$xdoc->findnodes('//s')});
    $Nw = scalar(@{$xdoc->findnodes('//w')});
  }

  ##-- ... and just return here
  return $xdoc;
}

##======================================================================
## Subs: sx stuff (*.sx)

## @sx_blocks : blocks parsed from .sx file:
## {
##  xoff=>$xoff,
##  xlen=>$xlen,
##  xp=>$xpath,   ##-- xpath without []-indices, and with initial m(^(?:/TEI(?\.[0-9])?)?(?:/text)?) removed
##  xpp=>$xpath,  ##-- xpath with []-indices
##  xr=>$rendition,
##  xc=>$context,
## }
our @sx_blocks = qw();

## $sx_blockv : vector index of blocks from .sx file
## + vec($sx_blockv,$i,32) == $sx_blocks[$i]{xoff}
our $sx_blockv = '';

## $Nsx : number of sx-records; $Nsx == scalar(@sx_blocks) == bytes::length($sx_blockv)/4;
our $Nsx = 0;

## $bool = load_sx($sxfile)
##  + loads sx data from $sxfile
##  + populates globals @sx_blocks, $sx_blockv
sub load_sx {
  my $xmlfile = shift;

  local $/ = undef;
  open(my $fh, "<$xmlfile") or die("$prog: FATAL: open failed for .sx-file $sxfile: $!");
  my $xmlbuf = <$fh>;
  close($fh);
  $xmlbuf =~ s|(<[^>]*\s)xmlns=|${1}XMLNS=|g;  ##-- remove default namespaces

  ##-- initialize LibXML parser
  my $parser = XML::LibXML->new();
  $parser->keep_blanks(0);
  $parser->line_numbers(1);
  $parser->load_ext_dtd($do_ext_dtd);

  ##-- load xml
  my $xdoc = $parser->parse_string($xmlbuf)
    or die("$prog: FATAL: could not parse .sx file from '$xmlfile': $!");

  ##-- descendants of these elements get marked in their 'xc' attribute
  my %xcontext_elts = (map {($_=>undef)}
		       qw(text front body back head foot end argument hi cit fw lg stage speaker formula table),
		       qw(div note), ##-- specially handled hacked elements
		       ##qw(left) ##-- DISABLED 2018-11-06 (mantis #31734)
		      );

  ##-- populate sx-blocks
  @sx_blocks = qw();
  my ($cnod,$cn,$xoff,$xlen,$nrest,$xp,$xpp, @xr,@xc,$tmp,$aname);
  foreach $cnod (@{$xdoc->findnodes('//c[@n]')}) {
    next if (!($cn = $cnod->getAttribute('n')) || $cn =~ /\b0\z/); ##-- ignore block-nodes without tx data
    ($xoff,$xlen,$nrest) = split(' ',$cn,3);
    ($xpp = $cnod->nodePath()) =~ s{\/c[^\/]*$}{};
    ($xp = $xpp) =~ s{\[[0-9]+\]}{}g;
    $xp =~ s{^/(?:(?:TEI(?:\.[0-9])?/)?(?:text/)?)}{};

    @xr = @xc = qw();
    foreach (@{$cnod->findnodes('ancestor::*')}) {
      push(@xr,$tmp) if ( ($tmp=$_->getAttribute('rendition')) );
      if ( ($aname=$_->nodeName) eq 'note' ) {
	##-- context: note: mark @place attribute
	push(@xc, "note_".($_->getAttribute('place')||'other'));
      }
      elsif ( ($aname=$_->nodeName) eq 'div' ) {
	##-- context: div: mark @type attribute
	push(@xc, "div_".($_->getAttribute('type')||'other'));
      }
      elsif (exists($xcontext_elts{$aname})) {
	##-- context: element-based
	push(@xc, $aname);
      }
    }
    push(@sx_blocks, {xoff=>$xoff,xlen=>$xlen,xp=>$xp,xpp=>$xpp,xr=>join(' ',luniq(@xr)),xc=>join(' ',luniq(@xc))});
  }

  ##-- sort block-list
  @sx_blocks = sort {$a->{xoff}<=>$b->{xoff} || $a->{xlen}<=>$b->{xlen}} @sx_blocks;

  ##-- populate block index
  $Nsx = scalar(@sx_blocks);
  $sx_blockv = '';
  vec($sx_blockv,$Nsx-1,32) = 0 if ($Nsx>0); ##-- allocate
  my $blki = 0;
  foreach (@sx_blocks) {
    vec($sx_blockv,$blki,32) = $_->{xoff};
    ++$blki;
  }

  ##-- ... and return true
  return 1;
}

##======================================================================
## Subs: cx stuff (*.cx)

##--------------------------------------------------------------
## cx stuff: cx-character record packing

## $cn2xoffv : $xoff == c_unpack(cn2packed($cn))->{xoff} == vec($cn2xoffv,$cn,32)
our $cn2xoffv = '';

## $Ncx     : number of cx-records : bytes::length($c_packed)/$c_pack_size == bytes::length($cn2xoffv)/4
## $Ncx_est : estimated number of cx-records, for pre-allocation
our $Ncx = 0;
our $Ncx_est = 0;

## cx-bin (v0.49): source constants [see dtatwCommon.h, DTA::TokWrap::CxData]
## @c_pkeys : \%c keys for local (un)packing
our @c_pkeys = qw(cn typ   xo xl   pb lb   ulx uly lrx lry);

## $c_pack : pack format for local c_pack(), c_unpack()
our $c_pack = 'lC(lC)(LL)(llll)';

## $c_pack_size
our $c_pack_size = bytes::length(pack($c_pack, map {0} @c_pkeys));

## $c_packed : $c_packed = bytes::substr($cn2packed, $cn*$c_pack_size, $c_pack_size)
our $cn2packed = '';

## $c_packed = cn2packed($cn)
sub cn2packed {
  use bytes;
  return substr($cn2packed, $_[0]*$c_pack_size, $c_pack_size);
}

## $c_packed_or_undef = c_pack(\%c)
sub c_pack {
  #no warnings qw(uninitialized numeric);
  return undef if (!defined($_[0]));
  return pack($c_pack, @{$_[0]}{@c_pkeys});
}
## \%c_or_undef = c_unpack($c_packed)
sub c_unpack {
  return undef if (!defined($_[0]));
  my $c = {};
  @$c{@c_pkeys} = unpack($c_pack,$_[0]);
  return $c;
}

## \%c_or_undef = c_get($cn)
##  + wrapper for c_unpack(cn2packed($cn))
sub c_get {
  return c_unpack( substr($cn2packed, $_[0]*$c_pack_size, $c_pack_size) );
}

##======================================================================
## Subs: cx stuff (*.cx)


##--------------------------------------------------------------
## cx stuff: load cx-file

## $bool = load_cx($cxfile)
##  + loads cx data from $cxfile
##  + populates globals $cn2packed, $cn2xoffv
sub load_cx {
  use bytes;
  my $cxfile = shift;
  open(CX,"<$cxfile") or die("$prog: FATAL: open failed for .cx-file $cxfile: $!");
  binmode(CX,":raw");

  ##-- cx: get and check header
  eval { cx_check_header(cx_get_header(\*CX)) }
    or die("$prog: FATAL: error reading cx-header from $cxfile: $@");

  my $lb=0;
  my ($pn,$pb)=(0,0);
  my $cn=0;
  my %c =qw();
  my %unescape = ('t'=>"\t",'n'=>"\n",'r'=>"\r",'\\'=>'\\');

  $cn2packed = '';
  $cn2xoffv  = '';

  ##-- pre-allocate (guesstimate)
  $Ncx_est = int( (-s CX) / 2 );
  vec($cn2xoffv,  $Ncx_est, 32)=0;
  vec($cn2packed, $Ncx_est*$c_pack_size, 8)=0;

  my $xmlOffset = 0;
  my ($cxr,$typ,$facs);
  while (!eof(CX)) {
    $cxr = cx_get_record(\*CX,$xmlOffset);
    $typ = $cxr->[$CX_FLAGS] & $cxfTypeMask;
    last if ($typ == $cxrEOF);

    if ($cxr->[$CX_TLEN] > 0) {
      ##-- text element: treat it as a logical character
      @c{qw(cn typ xo xl pb lb xr)} = ($cn,$typ, @$cxr[$CX_XOFF,$CX_XLEN], $pb,$lb, ''); ##-- no "rendition" attribute saved!
      @c{qw(ulx uly lrx lry)} = map {defined($_) ? $_ : -1} @$cxr[$CX_ATTR_ULX..$CX_ATTR_LRY];
      substr($cn2packed, $cn*$c_pack_size, $c_pack_size) = c_pack(\%c);
      vec($cn2xoffv,$cn,32) = $cxr->[$CX_XOFF];
      ++$cn;
      ++$lb if ($typ == $cxrLb);
    }
    elsif ($typ == $cxrPb) {
      ++$pn;
      if (defined($facs = $cxr->[$CX_ATTR_FACS])) {
	$pb = $facs;
	warn("$prog: WARNING: invalid \@facs for ${pn}-th <pb> from $cxfile record number $cn")
	  if ($facs == 0xffffffff && $warn_on_bad_facs && ++$n_warnings{pb_bad_facs}<=10);
      } else {
	warn("$prog: WARNING: no \@facs attribute for ${pn}-th <pb> at $cxfile record number $cn")
	  if ($warn_on_bad_facs && ++$n_warnings{pb_no_facs}<=10);
	$pb = $pn;
      }
      $lb = 1;
    }
    ##-- neither text-carrier nor <pb/>: silently ignore

    ##-- update position tracker(s)
    $xmlOffset = $cxr->[$CX_XOFF] + $cxr->[$CX_XLEN];
  }
  close(CX);

  ##-- get number of //c records, and truncate vectors
  $Ncx = $cn;
  if ($Ncx < $Ncx_est) {
    substr($cn2xoffv, $Ncx*4) = '';
    substr($cn2packed, $Ncx*$c_pack_size) = '';
  }

  ##-- return true
  return 1;
}

##======================================================================
## Subs: lookup utils

## \@cns = xb2cns($xb)
##  + uses globals @_cns, $_xoff, $_xlen, $_cn
my (@_cns,$_xoff,$_xend, $_cn);
sub xb2cns {
  @_cns = qw();
  while ($_[0] =~ /\b([0-9]+)\+([0-9]+)/g) {
    ($_xoff,$_xend) = ($1,$1+$2);
    $_xend = $_xoff+1 if ($_xend==$_xoff); ##-- check because formulae have xlen==0 !
    for ($_cn=vbsearch($cn2xoffv,$_xoff,32); ($_cn < $Ncx) && (vec($cn2xoffv,$_cn,32) < $_xend); ++$_cn) {
      push(@_cns,$_cn);
    }
  }
  return \@_cns;
}

## \@cs = xb2cs($xb)
##  + wrapper for [map {c_get($_)} @{xb2cns($_[0])}]
sub xb2cs {
  #return [ map {c_unpack($_)} @cn2packed[@{xb2cns($_[0])}] ];
  return [ map {c_get($_)} @{xb2cns($_[0])} ];
}


##======================================================================
## Subs: merge

our ($wnods,@wfml,@wnoc,$cn2wn);

## $xdoc = apply_ddc_attrs($xdoc)
##  + calls apply_word() on all nodes
##  + implements basic fallbacks
sub apply_ddc_attrs {
  my $xdoc = shift;

  ##--------------------------------------
  ## apply: pass=1: the "easy" stuff
  print STDERR "$prog: apply(pass=1) ... \n" if ($verbose>=$vl_progress);
  $wnods = $xdoc->findnodes('//w');  ##-- all //w nodes
  @wnoc  = qw();                     ##-- indices in @$wnods: //w nodes with no //c/@id list
  @wfml  = qw();                     ##-- indices in @$wnods: formula //w nodes
  $cn2wn = '';                       ##-- maps //c indices to //w indices of claiming wnod ("good" wnods only)
  my ($wi);
  for ($wi=0; $wi <= $#$wnods; $wi++) {
    apply_word($wi);
  }

  ##--------------------------------------
  ## apply: pass=2: formulae
  print STDERR "$prog: apply(pass=2): ", ($do_bbox ? "bbox" : "DISABLED"), " ...\n" if ($verbose>=$vl_progress);
  if ($do_bbox) {
    my ($c0,$wnod,@cs,@lprev_cs,@lnext_cs,$yprev,$ynext);
    my @clist_context = (1..1);
    foreach $wi (@wfml) {
      ##-- get //c list
      $wnod = $wnods->[$wi];
      @cs  = @{xb2cs($wnod->getAttribute('xb')||'')};
      next if (!defined($c0=$cs[0]));

      ##-- get characters by surrounding line(s)
      @lprev_cs = grep {$_->{typ}==$cxrChar && vec($cn2wn,$_->{cn},32)} map {clist_byline($c0->{pb}, $c0->{lb}-$_, $c0->{cn})} @clist_context;
      @lnext_cs = grep {$_->{typ}==$cxrChar && vec($cn2wn,$_->{cn},32)} map {clist_byline($c0->{pb}, $c0->{lb}+$_, $c0->{cn})} @clist_context;

      ##-- get line bbox (min,max)
      $yprev = lmax(grep {defined($_) && $_>=0} map {$_->{lry}} @lprev_cs);
      $ynext = lmin(grep {defined($_) && $_>=0} map {$_->{uly}} @lnext_cs);

      ##-- defaults
      $yprev = -1 if (!defined($yprev) || $yprev <= 0);
      $ynext = -1 if (!defined($ynext) || $ynext <= 0);

      ##-- maximum bbox size hack
      if ($ynext>=0 && $yprev>=0 && abs($ynext-$yprev) > $MAX_FORMULA_PIX) {
	$yprev=$ynext=-1;
      }

      ##-- top/bottom of page
      if ($yprev >= 0 && ($ynext < 0 || !@lnext_cs)) {
	$ynext = $PAGE_BOTTOM_Y;
      }
      elsif ($ynext >= 0 && ($yprev < 0 || !@lprev_cs)) {
	$yprev = $PAGE_TOP_Y;
      }

      ##-- bbox sanity condition
      ($yprev,$ynext) = ($ynext,$yprev) if ($ynext>=0 && $yprev>=0 && $ynext < $yprev);

      ##-- minimum-height check
      if ($yprev>=0 && $ynext>=0 && abs($ynext-$yprev)<$MIN_FORMULA_PIX) {
	my $growby = ($MIN_FORMULA_PIX - abs($ynext-$yprev))/2;
	$yprev -= $growby;
	$ynext += $growby;
      }

      ##-- ensure integer
      $yprev = int($yprev-0.5);
      $ynext = int($ynext+0.5);

      ##-- assign line-based bbox (if available)
      warn("$prog: WARNING: could not guess bbox for formula //w#", ($wnod->getAttribute('id')||'-'), " at $txmlfile line ", $wnod->line_number, "\n")
	if ($verbose >= $vl_warn && ($yprev<0 && $ynext<0));

      $wnod->setAttribute($bbox_attr, join('|', (-1,$yprev,-1,$ynext)));
    }
  }

  ##--------------------------------------
  ## apply: pass=3: remove 'c','b','xb' attributes if requested
  print STDERR "$prog: apply(pass=3): remove attrs ...\n" if ($verbose>=$vl_progress);
  if (!$do_keep_c) {
    foreach (@$wnods) {
      $_->removeAttribute('c');
      $_->removeAttribute('cs');
    }
  }
  if (!$do_keep_b) {
    foreach (@$wnods) {
      $_->removeAttribute('b');
    }
  }
  if (!$do_keep_xb) {
    foreach (@$wnods) {
      $_->removeAttribute('xb');
    }
  }

  return $xdoc;
}

## undef = apply_word($w_index)
## undef = apply_word($w_index)
##  + uses globals: $wnods, $bbsingle, ...
##  + populates globals: ($wnod,$wid,$cids,@cids,$wpage,$wrend,$wcon,$wxpath,@wbboxes)
my ($wi,$wnod,$wid,$wxb,@cs,@blks,  $off,$len,$wpage,$wline);
my ($brend,$crend,$wrend,$wcon,$wxpath,$bbsingle);
my ($wcs,@wbboxes,@cbboxes,$cbbox,$wbbox,$wtxt,$utxt,$w_is_formula);
my ($poff,$plen);
sub apply_word {
  ($wi) = @_;
  $wnod = $wnods->[$wi];

  ##-- get id
  if (!defined($wid=$wnod->getAttribute('id'))) {
    ##-- ...and ensure it's in the raw '//w/@id' attribute and not 'xml:id'
    if (defined($wid=$wnod->getAttribute('xml:id'))) {
      $wnod->getAttributeNode('xml:id')->setNamespace('','');
    } else {
      $wid = '-'; ##-- nil id
    }
  }

  ##-- get xml byte-range
  $wxb = $wnod->getAttribute('xb')||'';
  if ($wxb eq '' && $verbose >= $vl_warn && ++$n_warnings{empty_xb}<=10) {
    no warnings 'uninitialized';
    warn("$prog: WARNING: no xml byte-range attribute \@xb for //w#$wid at $txmlfile line ", $wnod->line_number, "\n");
  }

  ##-- get cx records
  @cs  = @{xb2cs($wxb)};
  if ($wxb && !@cs && $warn_on_empty_clist && $verbose >= $vl_warn && ++$n_warnings{empty_clist}<=10) {
    ##-- $wnod without a //c-list
    ##   + this happens e.g. for 'FORMEL' inserted via DTA::TokWrap::mkbx0 'hint_replace_xpaths'
    ##   + push these to @wnoc and try to fudge them in a second pass (see below)
    no warnings 'uninitialized';
    warn("$prog: WARNING: no cx-list for //w#$wid \[\@xb=\"$wxb\"] at $txmlfile line ", $wnod->line_number, "\n");
  }

  ##-- get sx records
  @blks = @{vabsearch_lb($sx_blockv,[map {$_->{xo}} @cs],32)};
  $cs[$_]{blk} = $sx_blocks[$blks[$_]] foreach (grep {$blks[$_] != $NOKEY} (0..$#blks));
  @blks = @sx_blocks[ luniq(grep {$_ != $NOKEY} @blks) ];
  if (@cs && !@blks && $warn_on_empty_blist && $verbose >= $vl_warn && ++$n_warnings{empty_blist}<=10) {
    ##-- $wnod outside of any source block
    ##  + does this ever happen?
    no warnings 'uninitialized';
    warn("$prog: WARNING: no sx-block-list for //w#$wid \[\@xb=\"$wxb\"] at $txmlfile line ", $wnod->line_number, "\n");
  }

  ##-- compute & assign: whitespace-separation (wsep: does whitespace precede this word?)
  if ($do_wsep) {
    ($off,$len) = split(' ', ($wnod->getAttribute('b')||''), 2);
    $off = -1 if (!defined($off) || $off eq '');
    $len =  1 if (!defined($len) || $len eq '');
    ($poff,$plen) = $wi>0 && $wnods->[$wi-1] ? split(' ', ($wnods->[$wi-1]->getAttribute('b')||''), 2) : (0,0);
    $wnod->setAttribute($wsep_attr, ($off == ($poff||0)+($plen||0) ? 0 : 1));
  }

  ##-- detect: formula
  $w_is_formula = (@cs && $cs[0]{typ}==$cxrFormula); #  || (@cids && $cids[0] =~ m/\$FORMULA:[0-9]+\$$/);

  ##-- get text
  $wtxt = $wnod->getAttribute('t') || $wnod->getAttribute('text') || '';
  utf8::upgrade($wtxt) if (!utf8::is_utf8($wtxt));

  ##-- compute & assign: formula text (non-empty @cids only)
  if ($formula_text ne '' && $w_is_formula) {
    $wtxt = $formula_text;
    $wnod->setAttribute('t',$wtxt);
  }

  ##-- compute & assign: whitespace-bashing
  if (!$keep_ws) {
    $wnod->setAttribute('t',$wtxt) if ($wtxt =~ s/\s/_/g);
  }

  ##-- compute & assign: unicruft
  if ($do_unicruft) {
    if ($wtxt =~ m(^[\x{00}-\x{ff}\p{Latin}\p{IsPunct}\p{IsMark}]*$)) {
      $utxt = Unicruft::utf8_to_utf8_de($wtxt);
    } else {
      $utxt = $wtxt;
    }
    $wnod->setAttribute($unicruft_attr,$utxt);
  }

  ##-- compute & assign: rendition (undef -> '-')
  my $xrhead = "head"; ##-- avoid 'Modification of a read-only value attempted at /usr/local/bin/dtatw-get-ddc-attrs.perl line 626.' errors
  if ($do_rendition) {
    $wrend = join($rend_sep,
		  map {s/^\#//;$_}
		  ##-- rendition: ANY-vs-ALL
		  ##
		  ##-- rendition: ALL: intersection: only those rendition properties shared by ALL characters of a word
		  #llintersect(map {[luniq (split(' ',($_->{xr}//'')),($_->{blk} ? split(' ',($_->{blk}{xr}//'')) : qw()))]} @cs),
		  ##
		  ##-- rendition: ANY: union: those rendition properties assigned to ANY character of a word
		  luniq( map {split(' ',($_->{xr}//'')),($_->{blk} ? split(' ',($_->{blk}{xr}//'')) : qw())} @cs ),
		  ##
		  ##--/rendition: ANY-vs-ALL
		  ($foreign
		   ? ((grep {$_ eq 'head'} map {split(' ',$_->{xc})} @blks) ? $xrhead : qw()) ##-- include 'head' context for non-DTA rendition lists
		   : qw()));
    $wnod->setAttribute($rendition_attr, $wrend ? "${rend_left}${wrend}${rend_right}" : '-');
  }

  ##-- compute & assign: structural context: xcontext (undef -> '-')
  if ($do_xcontext) {
    $wcon = join('|', luniq(map {split(' ',$_->{xc})} @blks));
    $wnod->setAttribute($xcontext_attr, $wcon ? "|$wcon|" : '-');
  }

  ##-- compute & assign: xpath (undef -> '/..' (== empty node set))
  if ($do_xpath) {
    $wxpath = @blks ? $blks[0]{xp} : undef;
    $wxpath = '/..' if (!defined($wxpath)); ##-- invalid xpath
    $wnod->setAttribute($xpath_attr, $wxpath);
  }

  ##-- compute & assign: xppath (undef -> '/..' (== empty node set))
  if ($do_xppath) {
    $wxpath = @blks ? $blks[0]{xpp} : undef;
    $wxpath = '/..' if (!defined($wxpath)); ##-- invalid xpath
    $wnod->setAttribute($xppath_attr, $wxpath);
  }

  ##-- compute & assign: page (undef -> -1; non-empty @cs only)
  if ($do_page) {
    $wpage = @cs ? $cs[0]{pb} : undef;
    $wpage = -1 if (!defined($wpage) || $wpage eq '');
    $wnod->setAttribute($page_attr, $wpage);
    warn("$prog: WARNING: invalid \@pb=-1 for //w#$wid at $txmlfile line ", $wnod->line_number, "\n")
      if (@cs && $wpage==-1 && $verbose >= $vl_warn && $warn_on_bad_page && ++$n_warnings{page}<=10);
  }

  ##-- compute & assign: line (undef -> -1; non-empty @cs only)
  if ($do_line) {
    $wline = @cs ? $cs[0]{lb} : undef;
    $wline = -1 if (!defined($wline) || $wline eq '');
    $wnod->setAttribute($line_attr, $wline);
  }

  ##-- compute & assign: bbox (undef -> ''; non-empty @cs only)
  if ($do_bbox && @cs) {
    @wbboxes = bboxes(\@cs,$bbsingle);
    $wnod->setAttribute($bbox_attr, join('_', map {join('|',@$_)} @wbboxes));
  }

  ##-- record: claim //c records
  vec($cn2wn, $_, 32) = $wi foreach (map {$_->{cn}} @cs);

  ##-- record: special attributes
  if ($w_is_formula) {
    push(@wfml,$wi);
  }
  elsif (!@cs) {
    ##-- @wnoc: //w node without //c-list
    push(@wnoc,$wi);
  }
}


##======================================================================
## Subs: generic

## @common = llintersect(\@list_of_lists)
##  + common elements from a list-of-lists; aka intersection akak join
my (%lli_tmp);
sub llintersect {
  %lli_tmp = qw();
  ++$lli_tmp{$_} foreach (map {@$_} @_);
  return grep {$lli_tmp{$_}==@_} keys %lli_tmp;
}

## @uniq = luniq(@list)
##  + unique elements from a list; aka union aka meet
my ($lu_tmp);
sub luniq {
  $lu_tmp=undef;
  return map {(defined($lu_tmp) && $lu_tmp eq $_ ? qw() : ($lu_tmp=$_))} sort @_;
}

## $min = lmin(@list)
my ($lmin_tmp);
sub lmin {
  $lmin_tmp=shift;
  foreach (grep {defined($_)} @_) {
    $lmin_tmp=$_ if (!defined($lmin_tmp) || $_ < $lmin_tmp);
  }
  return $lmin_tmp;
}

## $max = lmax(@list)
my ($lmax_tmp);
sub lmax {
  $lmax_tmp=shift;
  foreach (grep {defined($_)} @_) {
    $lmax_tmp=$_ if (!defined($lmax_tmp) || $_ > $lmax_tmp);
  }
  return $lmax_tmp;
}

## $avg = lavg(@list)
my ($lavg_tmp);
sub lavg {
  $lavg_tmp=undef;
  $lavg_tmp += $_ foreach (grep {defined($_)} @_);
  return undef if (!defined($lavg_tmp));
  return $lavg_tmp/scalar(@_);
}

## $median = lmedian(@list)
my (@lmed_tmp);
sub lmedian {
  @lmed_tmp = sort {$a<=>$b} grep {defined($_)} @_;
  return undef if (!@lmed_tmp);
  return scalar(@lmed_tmp)%2 == 0 ? (($lmed_tmp[@lmed_tmp/2-1]+$lmed_tmp[@lmed_tmp/2])/2) : @lmed_tmp[int(@lmed_tmp/2)];
}

## $stddev = lstddev(@list)
my ($lsd_ex,$lsd_ex2);
sub lstddev {
  return undef if (!defined($lsd_ex = lavg(@_)));
  $lsd_ex2 = lavg(map {$_**2} grep {defined($_)} @_);
  return sqrt($lsd_ex2 - $lsd_ex**2);
}

## @clist = clist_byline($page,$line,$cn0)
sub clist_byline {
  my ($pb,$lb,$cn0) = @_;
  $cn0 = 0 if (!defined($cn0));

  my ($cn,$c);
  my (@cs);
  ##-- stupid linear scan: backwards until $cn <= FIRST_CHAR($page,$line)
  for ($cn=$cn0; $cn > 0 && $cn < $Ncx; $cn--) {
    next if (!defined($c = c_get($cn)));
    last if ($c->{pb} < $pb || ($c->{pb}==$pb && $c->{lb} <  $lb));
    next if ($c->{pb} > $pb || ($c->{pb}==$pb && $c->{lb} >= $lb));
  }

  ##-- stupid linear scan: forwards until $cn >= LAST_CHAR($page,$line), pushing onto @cs
  for ( ; $cn >= 0 && $cn < $Ncx; $cn++) {
    next if (!defined($c = c_get($cn)));
    push(@cs,$c) if ($c->{pb}==$pb && $c->{lb}==$lb);
    last if ($c->{pb} >$pb || ($c->{pb}==$pb && $c->{lb} > $lb));
  }

  return @cs;
}

## @bboxes = bboxes(\@cs)
## @bboxes = bboxes(\@cs,$single=0)
##  + gets list of word bounding boxes @bboxes=($bbox1,$bbox2,...)
##    for a "word" composed of the characters in array-ref of cx-record \@cs
##  + each bbox $bbox in @bboxes is of the form
##      $bbox=[$ulx,$uly,$lrx,$lry]
##    with $ulx<=$lrx, $uly<=$lry; where a coordinate of -1 indicates undefined
##  + if $single is true, at most a single bbox will be returned, otherwise
##    line- and column-breaks will be heuristically detected
sub bboxes {
  ($wcs,$bbsingle) = @_;
  @wbboxes = qw();
  return @wbboxes if (!$wcs || !@$wcs);
  @cbboxes = map {[@$_{qw(ulx uly lrx lry)}]} grep {$_->{pb} == $wcs->[0]{pb}} @$wcs;
  $wbbox   = undef;
  foreach $cbbox (@cbboxes) {
    next if (grep {$_ < 0} @$cbbox); ##-- skip //c bboxes with bad values
    if (!$wbbox) {
      ##-- initial bbox
      @wbboxes = ($wbbox=[@$cbbox]);
      next;
    } elsif (!$bbsingle && $cbbox->[2] < $wbbox->[0]) {
      ##-- character:RIGHT << word:LEFT: probably a line-break: new word bbox
      push(@wbboxes, $wbbox=[@$cbbox]);
    } elsif (!$bbsingle && $cbbox->[3] < $wbbox->[1]) {
      ##-- character:BOTTOM >> word:TOP: probably a column-break: new word bbox
      push(@wbboxes, $wbbox=[@$cbbox]);
    } else {
      ##-- extend current word bbox
      $wbbox->[0] = $cbbox->[0] if ($cbbox->[0] < $wbbox->[0]);
      $wbbox->[1] = $cbbox->[1] if ($cbbox->[1] < $wbbox->[1]);
      $wbbox->[2] = $cbbox->[2] if ($cbbox->[2] > $wbbox->[2]);
      $wbbox->[3] = $cbbox->[3] if ($cbbox->[3] > $wbbox->[3]);
    }
  }
  return @wbboxes;
}


##======================================================================
## MAIN

##-- load .t.xml-file
print STDERR "$prog: loading t-xml file '$txmlfile'...\n"
  if ($verbose>=$vl_progress);
our $xdoc = load_txml($txmlfile);
print STDERR "$prog: loaded $Nw word(s) in $Ns sentence(s) from '$txmlfile'\n"
  if ($verbose>=$vl_info);

##-- load .sx-file
print STDERR "$prog: loading .sx-file '$sxfile'...\n"
  if ($verbose>=$vl_progress);
load_sx($sxfile) or die("$prog: FATAL: failed to load .sx-file '$sxfile'");
print STDERR "$prog: loaded $Nsx block record(s) from '$sxfile'.\n"
  if ($verbose>=$vl_info);

##-- load .cx-file
print STDERR "$prog: loading .cx-file '$cxfile'...\n"
if ($verbose>=$vl_progress);
load_cx($cxfile) or die("$prog: FATAL: failed to load .cx-file '$cxfile'");
print STDERR "$prog: loaded $Ncx character record(s) from '$cxfile' ".sprintf("[est = %d = %.0f%%]\n", $Ncx_est, ($Ncx ? (100*$Ncx_est/$Ncx) : 'nan'))
  if ($verbose>=$vl_info);

##-- apply attributes from .chr.xml file to .t.xml file
print STDERR "$prog: applying DDC-relevant attributes...\n"
  if ($verbose>=$vl_progress);
$xdoc = apply_ddc_attrs($xdoc);

##-- dump
print STDERR "$prog: dumping output file '$outfile'...\n"
  if ($verbose>=$vl_progress);
($outfile eq '-' ? $xdoc->toFH(\*STDOUT,$format) : $xdoc->toFile($outfile,$format))
  or die("$prog: ERROR: failed to write output file '$outfile': $!");






__END__

=pod

=head1 NAME

dtatw-get-ddc-attrs.perl - get DDC-relevant attributes from DTA::TokWrap files

=head1 SYNOPSIS

 dtatw-get-ddc-attrs.perl [OPTIONS] T_XML_FILE [SX_FILE=T_XML_FILE:.t.xml=.sx [CX_FILE=SX_FILE:.sx=.cx]]

 General Options:
  -help                  # this help message
  -verbose LEVEL         # set verbosity level (0<=LEVEL<=3)
  -quiet                 # be silent; alias for -verbose=0

 I/O Options:
  -output FILE           # specify output file (default='-' (STDOUT))
  -blanks , -noblanks    # do/don't keep 'ignorable' whitespace in T_XML_FILE file (default=don't)
  -dtd    , -nodtd       # do/don't load external DTDs (default=don't)
  -ws     , -nows        # do/don't keep whitespace in //w/@t (default=don't)
  -page   , -nopage      # do/don't extract //w/@pb (page-break; default=do)
  -line   , -noline      # do/don't extract //w/@lb (line-break; default=do)
  -rend   , -norend      # do/don't extract //w/@xr (rendition; default=do)
  -xcon   , -noxcon      # do/don't extract //w/@xc (xml context; default=do)
  -xpath  , -noxpath     # do/don't extract //w/@xp (trimmed xpath; default=do)
  -xppath , -noxppath    # do/don't extract //w/@xpp (untrimmed xpath; default=don't)
  -bbox   , -nobbox      # do/don't extract //w/@bb (bbox; default=don't)
  -xlit   , -noxlit      # do/don't extract //w/@u  (unicruft transliteration; default=do)
  -wsep   , -nowsep	 # do/don't extract //w/@ws (boolean space-separation; default=do)
  -keep-c , -nokeep-c    # do/don't keep existing //w/@c and //w/@cs attributes (default=keep)
  -keep-b , -nokeep-b    # do/don't keep existing //w/@b attributes (default=keep)
  -keep-xb, -nokeep-xb   # do/don't keep existing //w/@xb attributes (default=keep)
  -formula-text TEXT     # output text for //formula elements (default='' (no change))

=cut

##------------------------------------------------------------------------------
## Options and Arguments
##------------------------------------------------------------------------------
=pod

=head1 OPTIONS AND ARGUMENTS

Not yet written.

=cut

##------------------------------------------------------------------------------
## Description
##------------------------------------------------------------------------------
=pod

=head1 DESCRIPTION

Splice DDC-relevant attributes from DTA *.chr.xml files into DTA::TokWrap *.t.xml files.

=cut

##------------------------------------------------------------------------------
## See Also
##------------------------------------------------------------------------------
=pod

=head1 SEE ALSO

L<dtatw-add-c.perl(1)|dtatw-add-c.perl>,
L<dta-tokwrap.perl(1)|dta-tokwrap.perl>,
L<dtatw-add-ws.perl(1)|dtatw-add-w.perl>,
L<dtatw-splice.perl(1)|dtatw-splice.perl>,
L<dtatw-rm-c.perl(1)|dtatw-rm-c.perl>,
...

=cut

##------------------------------------------------------------------------------
## Footer
##------------------------------------------------------------------------------
=pod

=head1 AUTHOR

Bryan Jurish E<lt>moocow@cpan.orgE<gt>

=cut
