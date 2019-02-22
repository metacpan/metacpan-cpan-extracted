#!/usr/bin/perl -w

use IO::File;
use XML::LibXML;
use Getopt::Long qw(:config no_ignore_case);
use Encode qw(encode decode encode_utf8 decode_utf8);
use File::Basename qw(basename);
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

our $trim_xpath  = undef;   ##-- trim nodes matching this xpath
our $keep_header = 0;       ##-- keep old header?
our $keep_blanks = 0;       ##-- keep input whitespace?
our $format = 1;            ##-- output format level

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
	   'header-file|hf=s' => \$headfile,
	   'prepend|keep-old-header|keep-header|keep|k!' => \$keep_header,
	   'keep-blanks|blanks|whitespace|ws!' => \$keep_blanks,
	   'format|fmt!' => \$format,
	   'trim-xpath|trim|tx|t=s' => \$trim_xpath,
	   'output|out|o=s' => \$outfile,
	  );

pod2usage({-exitval=>0,-verbose=>0}) if ($help);

##-- command-line: arguments
$xmlfile = shift;
$xmlfile = '-' if (!$xmlfile);
$prog = "$prog: ".basename($xmlfile);

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
## MAIN

##-- grab .t.xml file into a libxml doc
print STDERR "$prog: loading XML file '$xmlfile'...\n" if ($verbose>=$vl_progress);
my $indoc = loadxml($xmlfile);
my $root  = $indoc->documentElement;

##-- grab header file
my ($headdoc);
if (defined($headfile)) {
  print STDERR "$prog: loading header file '$headfile'...\n" if ($verbose>=$vl_progress);
  $headdoc = loadxml($headfile)
}

##-- trim xpaths
my ($nod);
if ($trim_xpath) {
  print STDERR "$prog: trimming nodes matching XPath '$trim_xpath'...\n" if ($verbose>=$vl_progress);
  foreach $nod (@{$root->findnodes($trim_xpath)}) {
    $nod->parentNode->removeChild($nod);
  }
}
if ($headdoc && !$keep_header) {
  my $headname = $headdoc->documentElement->localname();
  print STDERR "$prog: trimming old header nodes via XPath //*[local-name()=\"$headname\"]...\n" if ($verbose>=$vl_progress);
  foreach $nod (@{$root->findnodes("//*[local-name()=\"$headname\"]")}) {
    $nod->parentNode->removeChild($nod);
  }
}

##-- append new header
if ($headdoc) {
  my $hroot = $headdoc->documentElement;
  if (defined(my $refnod=$root->firstChild)) {
    $root->insertBefore($hroot,$refnod);
  } else {
    $root->appendChild($hroot);
  }
}

##-- dump
print STDERR "$prog: dumping output XML file '$outfile'...\n"
  if ($verbose>=$vl_progress);
($outfile eq '-' ? $indoc->toFH(\*STDOUT,$format) : $indoc->toFile($outfile,$format))
  or die("$0: failed to write output XML file '$outfile': $!");


__END__

=pod

=head1 NAME

dtatw-insert-header.perl - (re-)insert headers into xml documents

=head1 SYNOPSIS

 dtatw-insert-header.perl [OPTIONS] XMLFILE

 General Options:
  -help                  # this help message
  -verbose LEVEL         # set verbosity level (0<=LEVEL<=1)
  -quiet                 # be silent

 I/O Options:
  -header HEADERFILE     # splice in teiHeader from HEADERFILE (default=none)
  -keep   , -nokeep      # do/don't keep existing header in XMLFILE (default=don't)
  -blanks , -noblanks    # do/don't keep 'ignorable' whitespace in DDC_TXML_FILE file (default=don't)
  -format , -noformat    # do/don't pretty-pring output (default=do)
  -trim XPATH            # trim all nodes matching XPATH from XMLFILE (default=none)
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
