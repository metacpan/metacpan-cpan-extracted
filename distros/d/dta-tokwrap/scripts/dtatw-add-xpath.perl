#!/usr/bin/perl -w

use IO::File;
use XML::Parser;
use Encode qw(encode_utf8 decode_utf8);
use Getopt::Long qw(:config no_ignore_case);
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
our $outfile = '-';
our ($outfh);

##-- vars: behavior
our @xp_elts = qw(w);
our @xp_attrs = qw();
our $xp_pos = 1;
our $out_attr = 'xp';
our $parent_xpath = 0;

##-- constants: verbosity levels
our $vl_warn     = 1;
our $vl_info     = 2;
our $vl_progress = 3;
our $verbose = $vl_progress;     ##-- print progress messages by default

##------------------------------------------------------------------------------
## Command-line
##------------------------------------------------------------------------------
GetOptions(##-- General
	   'help|h' => \$help,
	   'verbose|v=i' => \$verbose,
	   'quiet|q' => sub { $verbose=!$_[1]; },

	   ##-- I/O
	   'output|out|o=s' => \$outfile,

	   ##-- Behaviour
	   'elements|elts|e=s' => \@xp_elts,
	   'attributes|attrs|as=s' => \@xp_attrs,
	   'all-attributes|all-attrs|aas|aa' => sub {@xp_attrs=qw()},
	   'no-attributes|no-attrs|noattrs|no-as|noas|noa|A' => sub {@xp_attrs=qw(__NO_ATTRIBUTES__)},
	   'positions|pos|p!' => \$xp_pos,
	   'xpath-attribute|xpath-attr|xattr|xpa|xa|xp|x=s' => \$out_attr,
	   'parent-xpath|parent|px|P!' => \$parent_xpath,
	  );

pod2usage({-exitval=>0,-verbose=>0}) if ($help);

##-- command-line: arguments
$xmlfile = @ARGV ? shift : '-';
$prog  = "$prog: ".basename($xmlfile);

##-- source elts
@xp_elts = grep {defined($_) && $_ ne ''} map {split(/[\s\,]+/,$_)} @xp_elts;
pod2usage({-exitval=>1,-verbose=>0,-msg=>'no target elements defined!'}) if (!@xp_elts);
our %xp_elts = map {($_=>undef)} @xp_elts;

##-- source attrs
@xp_attrs = grep {defined($_) && $_ ne ''} map {split(/[\s\,]+/,$_)} @xp_attrs;

##======================================================================
## Subs

##--------------------------------------------------------------
## utils

## $escaped_utf8 = xmlesc($str_utf8)
my ($esc);
sub xmlesc {
  $esc = $_[0];
  $esc =~ s|\&|\&amp;|sg;
  $esc =~ s|\"|\&quot;|sg;
  $esc =~ s|\'|\&apos;|sg;
  $esc =~ s|\<|\&lt;|sg;
  $esc =~ s|\>|\&gt;|sg;
  #$esc =~ s|([\x{0}-\x{1f}])|'&#'.ord($1).';'|sge;
  return $esc;
}

##--------------------------------------------------------------
## XML::Parser handlers

our @stack = qw();
our $cur   = undef; ##-- current stack item

## undef = cb_init($expat)
sub cb_init {
  #$cnum = 0;
  @stack = ({elt=>'',attrs=>{},pos=>{},xp=>''});
  $cur   = $stack[0];
}

## undef = cb_start($expat, $elt,%attrs)
my ($_xp,$elt,%attrs, $prv,$ostr,$xpstr);
sub cb_start {
  ($_xp,$elt,%attrs) = @_;
  $prv = $cur;
  push(@stack, $cur={elt=>$elt,attrs=>{%attrs},pos=>{}});

  ##-- setup $cur->{xp}
  $cur->{xp} = $elt;
  if (!@xp_attrs) {
    $cur->{xp} .= join('', map {"[\@$_='".xmlesc($attrs{$_})."']"} sort keys %attrs);
  } else {
    $cur->{xp} .= join('', map {"[\@$_='".xmlesc($attrs{$_})."']"} grep {exists $attrs{$_}} @xp_attrs);
  }
  if ($xp_pos) {
    $cur->{xp} .= "[".(++$prv->{pos}{$cur->{xp}})."]";
  }
  $cur->{xp} = "$prv->{xp}/$cur->{xp}";

  ##-- check and possibly annotate
  if (exists($xp_elts{$elt})) {
    $ostr  = $_xp->original_string;
    $xpstr = ($parent_xpath ? $prv->{xp} : $cur->{xp});
    $xpstr = encode_utf8(" $out_attr=\"$xpstr\"");
    $ostr  =~ s{(\/?>)$}{${xpstr}$1};
    print $outfh $ostr;
    return;
  }

  ##-- just default
  $_xp->default_current();
}

## undef = cb_end($expat, $elt)
sub cb_end {
  pop(@stack);
  $cur = $stack[$#stack];
  $_[0]->default_current;
}

## undef = cb_char($expat,$string)

## undef = cb_default($expat, $str)
sub cb_default {
  print $outfh $_[0]->original_string;
}


##======================================================================
## MAIN

##-- xml parser
my $xp = XML::Parser->new(
		       ErrorContext => 1,
		       ProtocolEncoding => 'UTF-8',
		       #ParseParamEnt => '???',
		       Handlers => {
				    Init  => \&cb_init,
				    #Char  => \&cb_char,
				    Start => \&cb_start,
				    End   => \&cb_end,
				    Default => \&cb_default,
				    #Final => \&cb_final,
				   },
		      )
  or die("$prog: ERROR: couldn't create XML::Parser");

##-- output file
open($outfh, ">$outfile")
  or die("$0: open failed for output file '$outfile': $!");
binmode($outfh,':raw');

##-- input file
open(XML, "<$xmlfile")
  or die("$0: open failed for input file '$xmlfile': $!");
binmode(XML,':raw');
$xp->parse(\*XML);

##-- all done
close($outfh);


__END__

=pod

=head1 NAME

dtatw-add-xpath.perl - annotate canonical XPath for selected elements in an XML file

=head1 SYNOPSIS

 dtatw-add-xpath.perl [OPTIONS] XML_FILE

 General Options:
  -help                  # this help message
  -verbose LEVEL         # set verbosity level (0<=LEVEL<=3)
  -quiet                 # be silent; alias for -verbose=0

 I/O Options:
  -output FILE           # specify output file (default='-' (STDOUT))
  -elements ELEMENTS     # space- or comma-separated list of elements to annotate (default='w')
  -all-attrs , -no-attrs # do/don't include all attributes
  -pos       , -no-pos   # do/don't include xpath positions (default=do)
  -parent    , -noparent # do/don't annotate parent XPaths instead of target-node xpaths (default=-noparent)
  -xpath-attribute ATTR  # output attribute in which to annotate XPath (empty for all; default='': all)

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

Annotate canonical XPath for selected elements in an XML file.

=cut

##------------------------------------------------------------------------------
## See Also
##------------------------------------------------------------------------------
=pod

=head1 SEE ALSO

L<dtatw-get-ddc-attrs.perl(1)|dtatw-get-ddc-attrs.perl>,
...

=cut

##------------------------------------------------------------------------------
## Footer
##------------------------------------------------------------------------------
=pod

=head1 AUTHOR

Bryan Jurish E<lt>moocow@cpan.orgE<gt>

=cut
