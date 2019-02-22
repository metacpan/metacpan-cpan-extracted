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
our $verbose = 1;     ##-- print progress messages by default

##-- debugging
our $DEBUG = 0;

##-- vars: I/O
our $outfile = "-";   ##-- default: stdout

##-- constants: verbosity levels
our $vl_progress = 1;

##------------------------------------------------------------------------------
## Command-line
##------------------------------------------------------------------------------
GetOptions(##-- General
	   'help|h' => \$help,
	   'verbose|v=i' => \$verbose,
	   'quiet|q' => sub { $verbose=!$_[1]; },

	   ##-- I/O
	   'output|out|o=s' => \$outfile,
	  );

pod2usage({-exitval=>0, -verbose=>0}) if ($help);
pod2usage({-message=>"Not enough arguments given!", -exitval=>0, -verbose=>0,}) if (@ARGV < 0); ##-- never

##-- command-line: arguments
push(@ARGV,'-') if (!@ARGV);

##======================================================================
## Subs: XML::Parser handlers

## $_plevel: stack size when last <p> was opened, or -1 for none
## $_pn    : active //s/@pn attribute, if any
our ($_xp,$_elt,%_attrs, @stack,$_plevel,$_pn);

sub p_open {
  $outfh->print("<p>");
  $_plevel = @stack;
  $_pn = shift // '';
}
sub p_close {
  $outfh->print("</p>");
  $_plevel = -1;
  $_pn = undef;
}

## undef = cb_init($expat)
sub cb_init {
  #($_xp) = @_;
  @stack = qw();
  $_plevel = -1;
  $_pn = undef;
}

## undef = cb_start($expat, $elt,%attrs)
sub cb_start {
  ($_xp,$_elt,%_attrs) = @_;

  ##--------------------------
  if ($_elt eq 's' && (!defined($_pn) || $_pn ne ($_attrs{pn}//''))) {
    p_close() if (defined($_pn));
    p_open($_attrs{pn});
  }

  push(@stack,$_[1]);
  $_[0]->default_current();
}

## undef = cb_end($expat, $elt)
sub cb_end {
  pop(@stack);
  p_close() if ($_plevel>=0 && $_plevel > @stack); ##-- ensure last <p> gets closed
  $_[0]->default_current();
}

## undef = cb_char($expat,$string)
#sub cb_char {}

## undef = cb_default($expat, $str)
sub cb_default {
  $outfh->print($_[0]->original_string);
}

## undef = cb_comment($expat,$str)
#sub cb_comment {}

## undef = cb_final($expat)
#sub cb_final {}

##======================================================================
## MAIN

##-- initialize: @ARGV
push(@ARGV,'-') if (!@ARGV);

##-- initialize output file(s)
$outfile = '-' if (!defined($outfile));
our $outfh = IO::File->new(">$outfile")
  or die("$prog: open failed for output file '$outfile': $!");

##-- initial comments
$outfh->binmode(":raw");

##-- create XML::Parser object
our $xp = XML::Parser->new(
			   ErrorContext => 1,
			   ProtocolEncoding => 'UTF-8',
			   #ParseParamEnt => '???',
			   Handlers => {
					Init   => \&cb_init,
					Start  => \&cb_start,
					End    => \&cb_end,
					Default => \&cb_default,
					#Comment => \&cb_comment,
				       },
			  )
  or die("$prog: couldn't create XML::Parser object");

foreach my $infile (@ARGV) {
  $xp->parsefile($infile);
}

__END__

=pod

=head1 NAME

dtatw-pn2p.perl - insert <p> elements to wrap //s/@pn attributes in DTA::TokWrap .t.xml files

=head1 SYNOPSIS

 dtatw-pn2p.perl [OPTIONS] T_XML_FILE(s)...

 Options:
  -help                  # this help message
  -verbose LEVEL         # set verbosity level (0<=LEVEL<=1)
  -quiet                 # be silent
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

Insert <p> elements to wrap //s/@pn attributes in DTA::TokWrap .t.xml files.

=cut

##------------------------------------------------------------------------------
## See Also
##------------------------------------------------------------------------------
=pod

=head1 SEE ALSO

L<dtatw-add-c.perl(1)|dtatw-add-c.perl>,
L<dta-tokwrap.perl(1)|dta-tokwrap.perl>,
L<dtatw-add-ws.perl(1)|dtatw-add-ws.perl>,
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
