######################### -*- Mode: Perl -*- #########################
##
## $Basename: Makefile.PL $
## $Revision: 1.13 $
##
## Author           : Ulrich Pfeifer
## Created On       : Tue Aug 20 12:15:44 1996
##
## Last Modified By : Ulrich Pfeifer
## Last Modified On : Sun Apr  9 14:08:50 2000
## 
## Copyright (c) 1996-1997, Ulrich Pfeifer
## 
######################################################################

use strict;

use Config;
use ExtUtils::MakeMaker qw(:DEFAULT neatvalue);
use File::Path;
use Getopt::Long;

&check_perl(5.00307);  # need pack 'w', ...

my %OPT = (default => 0);
GetOptions(\%OPT, 'default!');

&init($OPT{default});

my @pl_files = glob('script/*');

my %seen;
my @objects = grep { s![^.]+$!o!; !$seen{$_}++ } glob('*.[cx]*');

WriteMakefile(
              'PREREQ_PM'    => {'Term::ReadLine'   => 0,
                                 'DB_File'          => 1.03,
                                 'Data::Dumper'     => 2.02,
                                 'Pod::Text'        => 1.02,
                                 'HTML::Entities'   => 0,
                                 'LockFile::Simple' => 0,
                                },
              'NAME'	     => 'WAIT',
              'OBJECT'       => join(' ', @objects),
# $Format: "   'VERSION'    => sprintf('%5.3f', ($ProjectMajorVersion$ * 100 + ( $ProjectMinorVersion$-1))/1000),"$ 
   'VERSION'    => sprintf('%5.3f', (18 * 100 + ( 1-1))/1000),
              'EXE_FILES'    => \@pl_files,
              'dist'         => {
				 PREOP => 'cp README.header README && pod2text lib/WAIT.pm >> README',
                                 SUFFIX   => 'gz',
                                 COMPRESS => 'gzip -9f',
                                },
             );


## ###################################################################
## subs
## ###################################################################

sub MY::postamble
{
  q[
lib/WAIT/Query/Wais.pm: waisquery.y
	byacc -P -l waisquery.y;
	sed -n '2,$$ p' y.tab.pl | ]. "$Config{cpp} $Config{cppminus}" .
          q[ | sed -e '/^# [0-9]/ d' > $@ && rm -f y.tab.pl

TAGS: MANIFEST
	etags `].$^X.q[ -ane 'print "$$F[0]\n"' MANIFEST`
 ]
}


sub init
{
  my $use_defaults = shift;
  
  $WAIT::Config = {};
  eval { require WAIT::Config; };
  
  my $answer;


  ## WAIT database directory
  print <<"EOF";
The WAIT module needs a directory of its own to store the databases.
This may be a site-wide directory or a personal directory.
EOF
;
  
  $answer = $WAIT::Config->{WAIT_home};
  $answer = '' unless $answer && -d $answer;
  $answer = prompt("WAIT database directory?", $answer) unless $use_defaults;
  
  mkpath($answer) unless $answer && -d $answer; # dies if it can't
  $WAIT::Config->{WAIT_home} = $answer;


  ## get manual pages
  my $help = q{ 

Now you need to tell me which manual directories you want to index.
If you want to enter a path, just type it in. To select a path type
'+' an the number. To deselect type '-' an the number. Enter 'q' if
you are finished.

};
  my %seen;
  my @manpath = @{$WAIT::Config->{manpath} ||
     [grep (-d $_, split(':', $ENV{MANPATH}),
                         '/usr/man',
             '/usr/local/man')]};

  @manpath = grep !$seen{$_}++, @manpath;
  my %select; @select{0 .. @manpath} = ('+') x @manpath;
  
  for (split(':', $ENV{MANPATH}), '/usr/man', '/usr/local/man') {
    next unless -d $_;
    next if $seen{$_};
    $select{@manpath} = '-';
    push @manpath, $_;
  }

  print $help;
  while (! $use_defaults) {
    my $i;
    for $i (0 .. $#manpath) {
      printf "%2d %c %s\n", $i, ord($select{$i}), $manpath[$i];
    }
    $answer = prompt("path|[+-]number|q>");
    if ($answer eq 'q') {
      last;
    } elsif ($answer =~ /^(\+|\-)\s*(\d+)?$/) {
      if (defined $2) {
        if (0 <= $2 and $2 <= $#manpath) {
          $select{$2} = $1;
        }
        else {
          print $help;
        }
      } else {
        for (keys %select) {
          $select{$_} = $1;
        }
      }
    } elsif (-d $answer) {
      push @manpath, $answer;
      $select{$#manpath} = '+';
    } else {
      print "Directory '$answer' does not seem to exists?\n";
      print $help;
    }
  }
  $WAIT::Config->{manpath} = [];
  my $i;
  foreach $i (0 .. $#manpath) {
    if ($select{$i} eq '+') {
      push @{$WAIT::Config->{manpath}}, $manpath[$i];
    }
  }

  
  ## pager
  print "\nWhat pager do you want to use?\n";
  print "Your perl administrator recommends '$Config{pager}'\n";
  print "We would prefer 'less', if you have that installed\n"
    unless $Config{pager} =~ /less/;
  
  $answer = $WAIT::Config->{pager} || $Config{pager} || 'less';
  $answer = prompt("pager?", $answer) unless $use_defaults;
  $WAIT::Config->{pager} = $answer;

  
  ## write config
  my $configpmdir = MM->catdir('lib', 'WAIT');
  mkpath $configpmdir;
  my $configpm = MM->catfile('lib', 'WAIT', 'Config.pm/' ); 
  
  open FH, "> $configpm" or die "Couldn't write open $configpm: $!\n";
  print FH qq[\$WAIT::Config = \{\n];
  foreach (sort keys %$WAIT::Config) {
    print FH "  '$_' => ", neatvalue($WAIT::Config->{$_}), ",\n";
  }
  
  print FH "};\n1;\n";
}


sub check_perl
{
  my $perlversion = shift;
  
  if ($] < $perlversion) {
    print <<"EOF";
Your Perl version is less than $perlversion. Please install a Perl with version
$perlversion or higher. Get it from CPAN: http://www.perl.org/CPAN/
EOF
    ;
    die "\n";
  }
  else {
    print "Your perl has version $] (higher than $perlversion). Ok!\n";
  }
}

