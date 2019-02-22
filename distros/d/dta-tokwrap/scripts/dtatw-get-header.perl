#!/usr/bin/perl -w

use IO::File;
use XML::Parser;
use Getopt::Long qw(:config no_ignore_case);
#use Encode qw(encode decode encode_utf8 decode_utf8);
use File::Basename qw(basename);
#use Time::HiRes qw(gettimeofday tv_interval);
use Pod::Usage;

use strict;

##------------------------------------------------------------------------------
## Constants & Globals
##------------------------------------------------------------------------------
our $prog = basename($0);
our ($help);

##-- debugging
our $DEBUG = 0;

##-- vars: I/O
our $outfile = "-";             ##-- default: stdout
our ($outfh);

##-- vars: selection
our $want_elt   = 'teiHeader';  ##-- header element name
our %want_attrs = qw();         ##-- required header attributes (literal match only)

##-- XML::Parser stuff
our ($xp); ##-- underlying XML::Parser object

##------------------------------------------------------------------------------
## Command-line
##------------------------------------------------------------------------------
GetOptions(##-- General
	   'help|h' => \$help,

	   ##-- I/O
	   'header-element|he|element|elt|e=s' => \$want_elt,
	   'header-attribute|ha|attribute|attr|a=s' => \%want_attrs,
	   'output|out|o=s' => \$outfile,
	  );


pod2usage({-exitval=>0,-verbose=>0}) if ($help);

##======================================================================
## Subs

##--------------------------------------------------------------
## XML::Parser handlers

our ($is_header);

## undef = cb_init($expat)
sub cb_init {
  $is_header = 0;
}

## undef = cb_xmldecl($expat,$version,$encoding,$standalone)
sub cb_xmldecl {
  $outfh->print($_[0]->original_string,"\n");
}

## undef = cb_char($expat,$string)
#sub cb_char {
#}

## undef = cb_start($expat, $elt,%attrs)
our (%attrs,$elt);
sub cb_start {
  %attrs = @_[2..$#_];
  ($elt=$_[1]) =~ s/^\w+://;
  ++$is_header if ($is_header || ($elt eq $want_elt && !grep {($attrs{$_}||'') ne $want_attrs{$_}} keys %want_attrs));
  $_[0]->default_current();
}

## undef = cb_end($expat, $elt)
sub cb_end {
  $_[0]->default_current();
  if ($is_header) {
    --$is_header;
    if ($is_header <= 0) {
      $outfh->print("\n");
      $outfh->close();
      exit (0);
    }
  }
}

## undef = cb_default($expat, $str)
##  + removes namespace prefixes on element tags
my ($str);
sub cb_default {
  return if (!$is_header);
  ($str = $_[0]->original_string) =~ s/^(<\/?)\w+:(\w+)/$1$2/;
  $outfh->print($str);
}

##======================================================================
## MAIN

##-- initialize XML::Parser
$xp = XML::Parser->new(
		       ErrorContext => 1,
		       ProtocolEncoding => 'UTF-8',
		       #ParseParamEnt => '???',
		       Handlers => {
				    Init  => \&cb_init,
				    XMLDecl => \&cb_xmldecl,
				    #Char  => \&cb_char,
				    Start => \&cb_start,
				    End   => \&cb_end,
				    Default => \&cb_default,
				    #Final => \&cb_final,
				   },
		      )
  or die("$prog: couldn't create XML::Parser");

##-- initialize output file(s)
$outfile = '-' if (!defined($outfile));
$outfh = IO::File->new(">$outfile")
  or die("$prog: open failed for output file '$outfile': $!");

##-- initialize: @ARGV
my $infile = @ARGV ? shift : '-';
$xp->parsefile($infile);

##-- oops: we should never get here: print a dummy header
$outfh->print("<$want_elt/><!-- dummy header created by $0 -->\n");
$outfh->close();

=pod

=head1 NAME

dtatw-get-header.perl - extract a header element from an XML file

=head1 SYNOPSIS

 dtatw-get-header.perl [OPTIONS] XMLFILE

 Options:
  -help                  # this help message
  -element ELEMENT       # specify header element (default='teiHeader')
  -attribute ATTR=VAL    # select only header elements with ATTR=VAL (may be multiply specifed)
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

Extract a header element from an XML file.

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
