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

##-- debugging
our $DEBUG = 0;

##-- vars: I/O
our $outfile = "-";          ##-- default: stdout

##-- XML::Parser stuff
our ($xp);    ##-- underlying XML::Parser object

##------------------------------------------------------------------------------
## Command-line
##------------------------------------------------------------------------------
GetOptions(##-- General
	   'help|h' => \$help,

	   ##-- I/O
	   'output|out|o=s' => \$outfile,
	  );


pod2usage({-exitval=>0,-verbose=>0}) if ($help);

##======================================================================
## Subs

##--------------------------------------------------------------
## XML::Parser handlers

## @stack = ({ns=>\@nsprefixes,re=>$regex},...)
## $nsreg = $stack[$#stack]
our @stack = qw();
our $nsre  = undef;

## undef = cb_init($expat)
sub cb_init {
  @stack = ({ns=>{}, re=>undef});
  $nsre  = $stack[0]{re};
}

## undef = cb_start($expat, $elt,%attrs)
my ($_str,%reg,$ns);
sub cb_start {
  %reg  = qw();
  $_str = $_[0]->original_string();
  $_str =~ s{\b_xmlns=}{xmlns=}g;
  $_str =~ s{\bxmlns_([\w\.]+)=}{"xmlns:".($reg{$1}=$1)."="}ge;
  if (%reg) {
    $ns   = {%{$stack[$#stack]{ns}},%reg};
    $nsre = '\b('.join('|', map {quotemeta($_)} sort keys %$ns).')'.'_([\w\.]+)(?=\W)';
    $nsre = qr{$nsre};
    push(@stack, {ns=>$ns,re=>$nsre});
  }
  else {
    push(@stack,$stack[$#stack]); ##-- duplicate top of stack
  }
  $_str =~ s{$nsre}{$1:$2}g if (defined($nsre));
  $outfh->print($_str);
}

## undef = cb_end($expat, $elt)
sub cb_end {
  $_str = $_[0]->original_string();
  $_str =~ s{$nsre}{$1:$2}g if (defined($nsre));
  $outfh->print($_str);

  pop(@stack);
  $nsre = $stack[$#stack]{re};
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
				    Char  => \&cb_default,
				    Start => \&cb_start,
				    End   => \&cb_end,
				    Default => \&cb_default,
				    #Proc    => \&cb_default,
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

##-- parse file(s)
foreach $infile (@ARGV) {
  $xp->parsefile($infile);
}
$outfh->close();


=pod

=head1 NAME

dtatw-restore-namespaces.perl - restore XML namespaces removed by dtatw-rm-namespaces

=head1 SYNOPSIS

 dtatw-restore-namespaces.perl [OPTIONS] [XMLFILE(s)...]

 Options:
  -help                  # this help message
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

Restore XML namespaces removed by dtatw-rm-namespaces.

=cut

##------------------------------------------------------------------------------
## See Also
##------------------------------------------------------------------------------
=pod

=head1 SEE ALSO

L<dta-rm-namespaces(1)|dta-rm-namespaces>,
...

=cut

##------------------------------------------------------------------------------
## Footer
##------------------------------------------------------------------------------
=pod

=head1 AUTHOR

Bryan Jurish E<lt>moocow@cpan.orgE<gt>

=cut
