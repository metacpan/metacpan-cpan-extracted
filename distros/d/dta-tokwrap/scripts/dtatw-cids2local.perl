#!/usr/bin/perl -w

use IO::File;
use XML::Parser;
use Getopt::Long qw(:config no_ignore_case);
use Encode qw(encode decode);
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
our $outfile = "-";     ##-- default: stdout
our $tracefile = undef; ##-- default: none
our $xmlns = '';        ##-- output namespace prefix (e.g. "xml:")

##-- XML::Parser stuff
our ($xp); ##-- underlying XML::Parser object

##-- other globals
our ($outfh,$tracefh);

##------------------------------------------------------------------------------
## Command-line
##------------------------------------------------------------------------------
GetOptions(##-- General
	   'help|h' => \$help,

	   ##-- I/O
	   'id-namespace|xmlns|idns|ns!' => sub { $xmlns=$_[1] ? 'xml:' : ''; },
	   'output-file|outfile|output|out|o=s' => \$outfile,
	   'trace-file|tracefile|trace|tf|t=s' => \$tracefile,
	   'trace-stderr|te' => sub { $tracefh=\*STDERR; },
	   'notrace' => sub { $tracefile=$tracefh=undef; }
	  );


pod2usage({
	   -exitval=>0,
	   -verbose=>0,
	  }) if ($help);

##======================================================================
## Subs

##--------------------------------------------------------------
## XML::Parser handlers

## undef = cb_init($expat)
our ($pb_i,$pb_facs,$pb_n, $pb_idstr);
our ($c_i);
sub cb_init {
  $text_depth = 0;
  $pb_i = $pb_facs = $pb_n = $c_i = 0;
  $pb_idstr = 'pz0';
}

## undef = cb_char($expat,$string)
## + NOT NEEDED

## undef = cb_start($expat, $elt,%attrs)
our (%attrs);
our ($cstr, $id_old, $id_new);
sub cb_start {
  if ($_[1] eq 'c') {
    %attrs = @_[2..$#_];

    ##-- get and remove old id
    $id_old = $attrs{'id'} || $attrs{'xml:id'};
    $cstr = $_[0]->original_string();
    $cstr =~ s/\b(?:xml:)?id=\"[^\"]*\"//;

    ##-- compute and add new id
    $id_new = "$pb_idstr.c".++$c_i;
    $cstr =~ s|\s*(/?>)$| ${xmlns}id="$id_new"$1|;

    ##-- maybe print trace
    $tracefh->print($id_old, "\t", $id_new, "\n") if (defined($tracefh));

    ##-- print output
    $outfh->print($cstr);
    return;
  }
  elsif ($_[1] eq 'pb') {
    %attrs = @_[2..$#_];
    ++$pb_i;
    $pb_n    = $attrs{n};
    $pb_facs = $attrs{facs};
    $pb_facs  =~ s/^\#?f?0*// if (defined($pb_facs));
    #$pb_facs  =~ s/^\#?// if (defined($pb_facs));
    if (defined($pb_facs)) {
      #$pb_idstr = 'pf'.$pb_facs;
      $pb_idstr = 'p'.$pb_facs;
    }
    #elsif (defined($pb_n)) { ##-- MAY RESULT IN NON-WF DATA ("validity error : xml:id : attribute value pn[V].c58 is not an NCName")
    #  $pb_idstr = 'pn'.$pb_n;
    #}
    else {
      $pb_idstr = 'pz'.$pb_i;
    }
    $c_i = 0;
  }
  ++$text_depth if ($_[1] eq 'text');
  $outfh->print($_[0]->original_string);
}

## undef = cb_end($expat, $elt)
sub cb_end {
  --$text_depth if ($_[1] eq 'text');
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
				    #Char  => \&cb_char,
				    Start => \&cb_start,
				    End   => \&cb_end,
				    Default => \&cb_default,
				    #Final => \&cb_final,
				   },
		      )
  or die("$prog: couldn't create XML::Parser");

##-- initialize: @ARGV
push(@ARGV,'-') if (!@ARGV);

##-- initialize output file(s)
$outfile = '-' if (!defined($outfile));
$outfh = IO::File->new(">$outfile")
  or die("$prog: open failed for output file '$outfile': $!");

if (defined($tracefile)) {
  $tracefh = IO::File->new(">$tracefile")
    or die ("$prog: open failed for trace file '$tracefile': $!");
  $tracefh->print("#OLD_ID\tNEW_ID\n");
}

##-- parse file(s)
foreach $infile (@ARGV) {
  $xp->parsefile($infile);
}
$outfh->close();


=pod

=head1 NAME

dtatw-cids2local.perl - convert //c/@xml:id attributes to page-local encoding

=head1 SYNOPSIS

 dtatw-cids2local.perl [OPTIONS] [XMLFILE(s)...]

 Options:
  -help                  # this help message
  -output FILE           # specify output file (default='-' (STDOUT))
  -trace  TRACEFILE      # send trace output to file (default=none)
  -xmlns , -noxmlns      # do/don't prepend 'xml:' to output id attributes (default=don't)

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

Converts C<//c/@xml:id> attributes to page-local encoding.

New IDs are computed page-locally, where the page element associated
with each C<//c> is given by the XPath C<preceding::pb[1]>, abbreviated
hereafter as $pb.  The associated $pb supplies a (unique) prefix C<$pbid> to all
//c elements on the given page.  The prefix is determined according to the following
rules:

=over 4

=item 1.

If $pb has a @facs attribute, it is used to define $pbid by removing any prefix
matching the regex C</#?f?0*/> and prefixing a "p", e.g. the following //pb elements
all map to $pbid="p42":

  <pb facs="42"/>
  <pb facs="#42"/>
  <pb facs="#f0042"/>
  <pb facs="f00042"/>
  <pb facs="000042"/>

=item 2.

Otherwise, a global counter over all //pb elements is used (whose value is initialized
to "0" (zero) before the initial //pb), prefixed by "pz".

                  <!-- before first page: $pbid="pz0" -->
  <pb />          <!-- first page, no @facs: $pbid="pz1" -->
  <pb />          <!-- second page, no @facs: $pbid="pz2" -->
  <pb facs="42"/> <!-- third page, with @facs: $pbid="p42" -->
  <pb />          <!-- fourth page: $pbid="pz4" -->

=back

Finally, //c/@xml:id attributes are computed by a page-local counter C<$ci>,
to be of the form C<${pbid}.c${ci}>, e.g.:

  <!-- before first page -->
  <c xml:id="pz0.c1"/>
  <c xml:id="pz0.c2"/>
  <!-- ... -->

  <!-- first page, with @facs -->
  <pb facs="#f0042"/>
  <c xml:id="p42.c1"/>
  <c xml:id="p42.c2"/>
  <!-- ... -->

  <!-- second page, no @facs -->
  <pb/>
  <c xml:id="pz2.c1"/>
  <c xml:id="pz2.c2"/>
  <!-- ... -->

=cut

##------------------------------------------------------------------------------
## See Also
##------------------------------------------------------------------------------
=pod

=head1 SEE ALSO

L<dta-tokwrap.perl(1)|dta-tokwrap.perl>,
L<dtatw-add-c.perl(1)|dtatw-add-c.perl>,
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
