#!/usr/bin/perl -w

use IO::File;
use XML::LibXML;
use Getopt::Long qw(:config no_ignore_case);
use Encode qw(encode decode encode_utf8 decode_utf8);
use File::Basename qw(basename);
#use Time::HiRes qw(gettimeofday tv_interval);
use Unicruft;
use Pod::Usage;

use strict;

##------------------------------------------------------------------------------
## Constants & Globals
##------------------------------------------------------------------------------
our $prog = basename($0);
our ($help);

##-- vars: I/O
our $xmlfile = undef;  ##-- required
our $headfile = undef; ##-- default: none
our $outfile  = "-";   ##-- default: stdout

our $keep_blanks = 0;       ##-- keep input whitespace?
our $format = 1;            ##-- output format level
our $wrap_paragraphs = 0;   ##-- insert <p> wrappers for //s/@pn ?
our $pb_xpath = '';         ##-- inert <pb> elements whenever $pb_xpath changes (relative to //w)?

##-- field selection
our @fields = qw();
our @fields_default = ('@u','@t','@bb','@pb','@xr','@xc');
our $val_default = '-'; ##-- default field value for empty or undefined fields

##-- constants: verbosity levels
our $vl_warn     = 1;
our $vl_progress = 2;
our $verbose = $vl_progress;     ##-- print progress messages by default

##-- globals: XML parser
our $parser = XML::LibXML->new();
$parser->keep_blanks($keep_blanks ? 1 : 0);
$parser->line_numbers(1);

##------------------------------------------------------------------------------
## Command-line
##------------------------------------------------------------------------------
GetOptions(##-- General
	   'help|h' => \$help,
	   'verbose|v=i' => \$verbose,
	   'quiet|q' => sub { $verbose=!$_[1]; },

	   ##-- I/O
	   'keep-blanks|blanks|whitespace|ws!' => \$keep_blanks,
	   'wrap-paragraphs|wrap-p|paragraphs|para|pwrap|p!' => \$wrap_paragraphs,
	   'pagebreak-xpath|pb-xpath|pbx|pb=s' => \$pb_xpath,
	   'header-file|hf=s' => \$headfile,
	   'index-field|index|i=s' => \@fields,
	   'output|out|o=s' => \$outfile,
	   'format|fmt!' => \$format,
	  );

pod2usage({-exitval=>0,-verbose=>0}) if ($help);

##-- command-line: arguments
our $txmlfile = shift;
$txmlfile = '-' if (!$txmlfile);
$prog = "$prog: ".basename($txmlfile);

@fields = @fields_default if (!@fields);

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
## X-Path utilities

## $val = nodval($nod)
sub nodval {
  return undef if (!defined($_[0]));
  return isa($_[0],'XML::LibXML::Attribute') ? $_[0]->nodeValue : $_[0]->textContent;
}

##======================================================================
## MAIN

##-- grab .t.xml file into a libxml doc
print STDERR "$prog: loading ddc-t-xml file '$txmlfile'...\n" if ($verbose>=$vl_progress);
my $indoc = loadxml($txmlfile);

##-- grab header file
my ($headdoc);
if (defined($headfile)) {
  print STDERR "$prog: loading header XML file '$headfile'...\n" if ($verbose>=$vl_progress);
  $headdoc = loadxml($headfile)
}

##-- create output document
print STDERR "$prog: creating output document...\n" if ($verbose >= $vl_progress);
my $outdoc  = XML::LibXML::Document->new("1.0","UTF-8");
my $outroot = XML::LibXML::Element->new("TEI");
$outdoc->setDocumentElement($outroot);

##-- populate output document: header
if ($headdoc) {
  $outroot->appendChild( $headdoc->documentElement->cloneNode(1) );
}

##-- populate output document: content
BEGIN { *isa=\&UNIVERSAL::isa; }
my $text = $outroot->addNewChild(undef,'text');
my $body = $text->addNewChild(undef,'body');
my ($s_in,$s_out, $w_in,$w_out, @wf, $np,$pn_in,$pn_out, $page_in,$pb_out);
my $parent = $wrap_paragraphs ? undef : $body;
my $page   = 0;

foreach $s_in (@{$indoc->findnodes('//s')}) {
  if ($wrap_paragraphs) {
    $pn_in = $s_in->getAttribute('pn')//'';
    if (!defined($pn_out) || $pn_out ne $pn_in) {
      $parent = $body->addNewChild(undef,'p');
      $pn_out = $pn_in;
    }
  }
  $s_out = $parent->addNewChild(undef,'s');
  foreach $w_in (@{$s_in->findnodes('w')}) {
    if ($pb_xpath && defined($page_in=nodval($w_in->findnodes($pb_xpath)->[0])) && $page_in ne $page && $page_in=~/^[0-9]+$/ && $page_in != 0) {
      $page = $page_in;
      $pb_out = $s_out->addNewChild(undef, 'pb');
      $pb_out->setAttribute('n'=>$page);
    }
    @wf = (
	   map {s/\s/_/g; $_}
	   map {utf8::is_utf8($_) ? $_ : decode_utf8($_)}
	   map {!defined($_) || $_ eq '' ? $val_default : $_}
	   map {isa($_,'XML::LibXML::Node') ? $_->textContent : $_}
	   map {isa($_,'XML::LibXML::Attr') ? $_->value : $_}
	   map {$w_in->findnodes($_)->[0]}
	   @fields
	  );
    $s_out->appendTextChild('l',join("\t", @wf));
  }
}

##-- dump
print STDERR "$prog: dumping output DDC file '$outfile'...\n"
  if ($verbose>=$vl_progress);
($outfile eq '-' ? $outdoc->toFH(\*STDOUT,$format) : $outdoc->toFile($outfile,$format))
  or die("$0: failed to write output DDC file '$outfile': $!");


__END__

=pod

=head1 NAME

dtatw-xml2ddc.perl - convert DTA::TokWrap ddc-t-xml files to DDC-parseable format

=head1 SYNOPSIS

 dtatw-xml2ddc.perl [OPTIONS] DDC_TXML_FILE

 General Options:
  -help                  # this help message
  -verbose LEVEL         # set verbosity level (0<=LEVEL<=1)
  -quiet                 # be silent

 I/O Options:
  -header HEADERFILE     # splice in teiHeader from HEADERFILE (default=none)
  -blanks , -noblanks    # do/don't keep 'ignorable' whitespace in DDC_TXML_FILE file (default=don't)
  -pwrap  , -nopwrap     # do/don't insert <p> elements to wrap //s/@pn keys (default=don't)
  -pb XPATH              # insert <pb n="$XPATH"/> milestones on $XPATH change, relative to //w (default:don't)
  -index XPATH           # set XPATH source for an output index field, relative to //w (overrides DTA defaults)
  -output FILE           # specify output file (default='-' (STDOUT))

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

Convert DTA::TokWrap .ddc.t.xml files to DDC XML format.

=cut

##------------------------------------------------------------------------------
## See Also
##------------------------------------------------------------------------------
=pod

=head1 SEE ALSO

L<dtatw-add-c.perl(1)|dtatw-add-c.perl>,
L<dta-tokwrap.perl(1)|dta-tokwrap.perl>,
L<dtatw-add-ws.perl(1)|dtatw-add-ws.perl>,
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
