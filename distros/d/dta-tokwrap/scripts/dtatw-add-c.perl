#!/usr/bin/perl -w

use IO::File;
use XML::Parser;
use Getopt::Long qw(:config no_ignore_case);
use Encode qw(encode_utf8 decode_utf8);
use File::Basename qw(basename);
use Time::HiRes qw(gettimeofday tv_interval);
use Pod::Usage;


##------------------------------------------------------------------------------
## Constants & Globals
##------------------------------------------------------------------------------
our $prog = basename($0);

##-- debugging
our $DEBUG = 0;

##-- vars: I/O
our $want_cids  = 0;		  ##-- bool: assign id attributes for auto-generated //c elements?
our $idns       = ''; #'xmlns:';  ##-- 'xml:' namespace prefix+colon for output id attributes (empty for none)
our $rmns	= 1;	  	  ##-- true causes default namespaces (xmlns="...") to be encoded as XMLNS="..."
our $outfile    = "-";            ##-- default: stdout


##-- profiling
our $profile = 0;
our $nchrs = 0;   ##-- total number of <c> tags generated
our $nxbytes = 0; ##-- total number of XML source bytes processed
our ($tv_started,$elapsed) = (undef,undef);

##-- XML::Parser stuff
our ($xp); ##-- underlying XML::Parser object

our $cnum = 0;           ##-- $cnum: global index of <c> element (number of elts read so far)
our $text_depth = 0;     ##-- number of open <text> elements
our $c_depth = 0;        ##-- number of open <c> elements (should never be >1)
our $c_is_space = 0;	 ##-- whether current <c> is a pure space (requires text node for dtatw-rm-c.perl consistency)

##------------------------------------------------------------------------------
## Command-line
##------------------------------------------------------------------------------
GetOptions(##-- General
	   'help|h' => \$help,

	   ##-- I/O
	   'id-namespace|idns|xmlns=s' => sub { $xmlns=$_[1] ? "xml:" : ''; }, ##-- bad name 'xmlns'
	   'no-idns|noxmlns' => sub { $xmlns=''; },
	   'cids|ids|cid|id!' => \$want_cids,

	   'rm-default-namespaces|rm-default-ns|rm-ns|rmns!' => \$rmns,
	   'keep-default-namespaces|keep-defaultns|keep-ns|keepns|ns!' => sub {$rmns=!$_[1]},

	   'guess|g!' => sub {;}, ##-- null-op for compatibility
	   'output|out|o=s' => \$outfile,
	   'profile|p!' => \$profile,
	  );


pod2usage({-exitval=>0,-verbose=>0}) if ($help);

##======================================================================
## Subs

##--------------------------------------------------------------
## debugging

sub debugmsg {
  return if (!$DEBUG);
  print STDERR "$prog: DEBUG: ", @_, "\n";
}

##--------------------------------------------------------------
## XML::Parser handlers

## undef = cb_init($expat)
sub cb_init {
  #$cnum = 0;
  $text_depth = 0;
  $c_depth = 0;
  $c_is_space = 0;
}

## undef = cb_char($expat,$string)
our ($c_block,$c_char,$c_rest, $cs);
sub cb_char {
  if ($c_depth > 0) {
    $c_is_space = ($_[1] eq ' ') if ($c_depth>0);
    $outfh->print($_[0]->original_string());
    return;
  }
  elsif ($text_depth <= 0) {
    $outfh->print($_[0]->original_string());
    return;
  }
  $c_block = decode_utf8( $_[0]->original_string() );
  while ($c_block =~ m/((?:\&[^\;]*\;)|(?:\s+)|(?:\X))/sg) {
    $c_char = $1;
    ##-- tricks for handling whitespace and newlines e.g. in:
    ##     http://kaskade.dwds.de/dtae/book/view/brandes_naturlehre02_1831?p=70
    if ($c_char =~ m/^\s+$/s) {
      ##-- whitespace (including newlines)
      $c_rest = encode_utf8($c_char);
      $c_char = ' ';
    } else {
      $c_rest = '';
    }
    $outfh->print("<c", ($want_cids ? (" ${idns}id=\"c", ++$cnum, "\"") : qw()), ">", encode_utf8($c_char), "</c>", $c_rest);
  }
}

## undef = cb_start($expat, $elt,%attrs)
sub cb_start {
  if ($_[1] eq 'c') {
    ##-- pre-existing <c>: respect it
    if ($c_depth > 0) {
      $_[0]->xpcroak("$prog: ERROR: cowardly refusing to process input document with nested <c> elements!");
    }
    ++$c_depth;
    $cs = $_[0]->original_string();
    if ($want_cids && $cs !~ m/\s(?:xml\:)?id=\"[^\"]+\"/io) {
      ##-- pre-existing <c> WITHOUT xml:id attribute: assign one
      ++$cnum;
      $cs =~ s|(/?>)$| ${idns}id="c$cnum"$1|o;
    }
    ##-- ... and print
    $outfh->print($cs);
    return;
  }
  elsif ($_[1] eq 'text') {
    ++$text_depth;
  }
  $outfh->print($_[0]->original_string);
}

## undef = cb_end($expat, $elt)
sub cb_end {
  if ($_[1] eq 'c') {
    --$c_depth;
    $outfh->print($_[0]->original_string(), ($c_is_space ? ' ' : qw()));
    $c_is_space = 0;
    return;
  }
  elsif ($_[1] eq 'text') {
    --$text_depth;
  }
  $outfh->print($_[0]->original_string);
}

## undef = cb_catchall($expat, ...)
##  + catch-all
sub cb_catchall {
  $outfh->print($_[0]->original_string);
}

## undef = cb_default($expat, $str)
*cb_default = \&cb_catchall;

##======================================================================
## MAIN

##-- initialize XML::Parser
$xp = XML::Parser->new(
		       ErrorContext => 1,
		       ProtocolEncoding => 'UTF-8',
		       #ParseParamEnt => '???',
		       Handlers => {
				    Init  => \&cb_init,
				    Char  => \&cb_char,
				    Start => \&cb_start,
				    End   => \&cb_end,
				    Default => \&cb_default,
				    #Final => \&cb_final,
				   },
		      )
  or die("$prog: ERROR: couldn't create XML::Parser");

##-- initialize: @ARGV
push(@ARGV,'-') if (!@ARGV);

##-- initialize output file(s)
$outfile = '-' if (!defined($outfile));
$outfh = IO::File->new(">$outfile")
  or die("$prog: ERROR: open failed for output file '$outfile': $!");

##-- initialize: profiling info
$tv_started = [gettimeofday] if ($profile);

##-- parse file(s)
foreach $infile (@ARGV) {
  $prog = basename($0).": $infile";

  ##-- slurp input file
  local $/=undef;
  open(XML,"<$infile") or die("$prog: ERROR: open failed for input file '$infile': $!");
  $buf = <XML>;
  close XML;

  ##-- encode default namespaces if requested
  $buf =~ s|(<[^>]*\s)xmlns=|${1}XMLNS=|g if ($rmns);

  ##-- initialize $cnum counter by checking any pre-assigned //c/@id values (fast regex hack)
  $cnum = 0;
  while ($buf =~ m/\<c\b[^\>]*\s(?:xml\:)?id=\"c([0-9]+)\"/isg) {
    $cnum = $1 if ($1 > $cnum);
  }
  debugmsg("initialized \$cnum=$cnum") if ($DEBUG);

  ##-- assign new //c elements (and maybe //c/@id attributes)
  $xp->parse($buf);

  ##-- profile
  $nchrs   += $cnum;
  $nxbytes += (-s $infile) if ($infile ne '-');
}
$outfh->close();

##-- profiling / output
sub sistr {
  my $x = shift;
  return sprintf("%.1f T", $x/10**12) if ($x >= 10**12);
  return sprintf("%.1f G", $x/10**9)  if ($x >= 10**9);
  return sprintf("%.1f M", $x/10**6)  if ($x >= 10**6);
  return sprintf("%.1f K", $x/10**3)  if ($x >= 10**3);
  return sprintf("%.1f  ", $x)        if ($x >= 1);
  return sprintf("%.1f m", $x*10**3)  if ($x >= 10**-3);
  return sprintf("%.1f u", $x*10**6)  if ($x >= 10**-6);
}

if ($profile) {
  $elapsed = tv_interval($tv_started,[gettimeofday]);
  $chrsPerSec  = sistr($elapsed > 0 ? ($nchrs/$elapsed) : -1);
  $bytesPerSec = sistr($elapsed > 0 ? ($nxbytes/$elapsed) : -1);

  print STDERR
    (sprintf("%s: %.1f chars ~ %d XML-bytes in %.2f sec: %schr/sec ~ %sbyte/sec\n",
	     $prog, $nchrs,$nxbytes, $elapsed, $chrsPerSec, $bytesPerSec));
}


=pod

=head1 NAME

dtatw-add-c.perl - add <c> elements to DTA XML documents

=head1 SYNOPSIS

 dtatw-add-c.perl [OPTIONS] [XMLFILE(s)...]

 General Options:
  -help                  # this help message

 I/O Options:
  -output FILE           # specify output file (default='-' (STDOUT))
  -cids  , -nocids	 # do/don't assign ids for auto-generated <c> elements (default=-nocids)
  -idns=NAMESPACE        # namespace prefix for id attributes, e.g. "xml:" (default=none)
  -rmns   , -keepns      # do/don't encode default namespaces as for dtatw-nsdefault-encode.perl (default=do)
  -profile, -noprofile   # output profiling information? (default=no)

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

Adds E<lt>cE<gt> elements to DTA XML files and/or assign C<xml:id>s to existing E<lt>cE<gt>s.

Pretty much useless as of dta-tokwrap v0.38.

=cut

##------------------------------------------------------------------------------
## See Also
##------------------------------------------------------------------------------
=pod

=head1 SEE ALSO

L<dta-tokwrap.perl(1)|dta-tokwrap.perl>,
L<dtatw-cids2local.perl(1)|dtatw-cids2local.perl(1)>,
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
