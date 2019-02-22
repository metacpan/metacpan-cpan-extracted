#!/usr/bin/perl -w

use IO::File;
use XML::Parser;
use Getopt::Long qw(:config no_ignore_case);
use File::Basename qw(basename);
use Pod::Usage;


##------------------------------------------------------------------------------
## Constants & Globals
##------------------------------------------------------------------------------
our $prog = basename($0);

##-- vars: debugging
our $DEBUG = 0;

##-- vars: I/O
our $byfile   = 1;     ##-- enable file-based heuristics?
our $byline   = 1;     ##-- enable line-based heuristics?
our $bytag    = 1;     ##-- enable element-based heuristics?
our $outfile  = "-";   ##-- default: stdout

our %lb_elts = map {($_=>undef)} qw(text body front back head div p);

##-- XML::Parser stuff
our ($xp); 		 ##-- underlying XML::Parser object

##------------------------------------------------------------------------------
## Command-line
##------------------------------------------------------------------------------
GetOptions(##-- General
	   'help|h' => \$help,

	   ##-- I/O
	   'by-file|byfile|bf|file|f!' => \$byfile,
	   'by-line|byline|bl|line|l!' => \$byline,
	   'by-tag|bytag|bt|tag|t|by-element|byelement|by-elt|byelt|be|element|elt|e!' => \$bytag,
	   'output|out|o=s' => \$outfile,
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

our $text_depth = 0;     ##-- number of open <text> elements
our $last_was_lb = 0;

## undef = cb_init($expat)
sub cb_init {
  #$cnum = 0;
  $text_depth = 0;
  $last_was_lb = 0;
}

## undef = cb_char($expat,$string)
my ($str);
sub cb_char {
  if ($text_depth <= 0) {
    $outfh->print($_[0]->original_string());
    return;
  }
  $str = $_[0]->original_string();
  utf8::decode($str) if (!utf8::is_utf8($str));
  if ($byline && $last_was_lb) {
    ##-- apply line heuristics
    $outfh->print($1) if ($str =~ s/^(\R)//);
    $last_was_lb = ($str =~ /^\s*$/s);
  }

  $last_was_lb ||= ($byline && $str =~ /\R\z/);
  $str =~ s{(\R)}{<lb/>$1}sg;           ##-- map internal newlines
  utf8::encode($str) if (utf8::is_utf8($str));
  $outfh->print($str);
}

## undef = cb_start($expat, $elt,%attrs)
sub cb_start {
  ++$text_depth if ($_[1] eq 'text');
  $outfh->print($_[0]->original_string);
  if ($bytag && !$last_was_lb && $text_depth > 0 && exists($lb_elts{$_[1]})) {
    $outfh->print("<lb/>");
    $last_was_lb = 1;
  }
}

## undef = cb_end($expat, $elt)
sub cb_end {
  --$text_depth if ($_[1] eq 'text');
  if ($bytag && !$last_was_lb && $text_depth > 0 && exists($lb_elts{$_[1]})) {
    $outfh->print("<lb/>");
    $last_was_lb = 1;
  }
  elsif ($_[1] eq 'lb' && $text_depth > 0) {
    $last_was_lb = 1;
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

##-- tweak input file(s)
foreach $infile (@ARGV) {
  $prog = basename($0).": $infile";

  ##-- slurp input file (for file-based heuristics)
  local $/=undef;
  open(XML,"<$infile") or die("$prog: ERROR: open failed for input file '$infile': $!");
  $buf = <XML>;
  close XML;

  if ($byfile && $buf =~ m{<\s*lb\b[^\>]>}is) {
    ##-- file already contains at least one <lb>: pass through unchanged
    debugmsg("input file '$infile' already contains line-breaks: skipping");
    $outfh->print($buf);
  } else {
    ##-- file contains no <lb>: tweak it
    $xp->parse($buf);
  }
}
$outfh->close();


=pod

=head1 NAME

dtatw-ensure-lb.perl - ensure <lb/> elements end text lines in DTA/D* XML documents

=head1 SYNOPSIS

 dtatw-ensure-lb.perl [OPTIONS] [XMLFILE(s)...]

 General Options:
  -help                  # this help message

 I/O Options:
  -byfile , -nofile      # do/don't enable file-based heuristics (default=do)
  -byline , -noline      # do/don't enable line-based heuristics (default=do)
  -byelt  , -noelt       # do/don't enable element-based heuristics (default=do)
  -output FILE           # specify output file (default='-' (STDOUT))

=cut

##------------------------------------------------------------------------------
## Options and Arguments
##------------------------------------------------------------------------------
=pod

=head1 OPTIONS AND ARGUMENTS

=over 4

=item -help

Display a brief help message.

=item -byfile , -nofile

Do/don't enable file-based heuristics.
If enabled (default), no E<lt>lbE<lt> elements will be added to any
input file containing at least one E<lt>lbE<lt> element in it already.

=item -byline , -noline

Do/don't enable line-based heuristics.
If enabled (default), no E<lt>lbE<lt> elements will be added to any
input text line which is already immediately preceded by an existing E<lt>lbE<lt> element.

=item -byelt , -noelt

Do/don't enable element-based heuristics.
If enabled (default), E<lt>lbE<lt> elements will be added before and after the
the content of the following XML tags:

 text body front back head div p

=item -output FILE

Set output filename.
By default, output is written to STDOUT.

=back

=cut

##------------------------------------------------------------------------------
## Description
##------------------------------------------------------------------------------
=pod

=head1 DESCRIPTION

Adds E<lt>clb/E<gt> elements at all literal text line-breaks lacking an immediately preceding E<lt>clb/E<gt>
to DTA/D* XML files.


=cut

##------------------------------------------------------------------------------
## See Also
##------------------------------------------------------------------------------
=pod

=head1 SEE ALSO

L<dta-tokwrap.perl(1)|dta-tokwrap.perl>,
...

=cut

##------------------------------------------------------------------------------
## Footer
##------------------------------------------------------------------------------
=pod

=head1 AUTHOR

Bryan Jurish E<lt>moocow@cpan.orgE<gt>

=cut
