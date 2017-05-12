use ExtUtils::MakeMaker;
use strict;

# All this should be done by the Makefile but I couldn't figure out
# how to tell this to ExtUtils::MakeMaker

# Verifies if gsl is installed.
my $gsl_ver = `gsl-config --version`;
chomp $gsl_ver;
die "The Gnu Scientific Library (GSL) needs to be installed\nhttp://www.gnu.org/software/gsl/\n" if $gsl_ver == 0;

my $gsl_inc = `gsl-config --cflags`;
chomp $gsl_inc;

my $gsl_libs = `gsl-config --libs`;
chomp $gsl_libs;

# Installation of the MI-TDT-example/ directory
my $source = "MI-TDT-example";
my $home = $ENV{'HOME'};
my @files = glob("$source/*");
if(-d "$home/$source" or mkdir("$home/$source"))
{
  print "Installing documentation and example files in $home/$source/...\n";
  for my $x (@files)
  {
    if(-e "$home/$x")
    {
      warn "$home/$x already exists, won't erase\n";
      next;
    }
    print "Copying $home/$x\n";
    link $x, "$home/$x" or warn "Can't copy $home/$x\n";
  }
}
else
{
  warn "Can't create $home/$source/ : won't install example files\n";
}


# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'VJF::MITDT',
    VERSION_FROM      => 'lib/VJF/MITDT.pm', # finds $VERSION
    PREREQ_PM         => {'Getopt::Lucid' => 0.16, 'VJF::Emphase' => 0.11}, # e.g., Module::Name => 1.1
    EXE_FILES         => ['bin/MI-TDT'],
    LIBS              => [ $gsl_libs ], # e.g., '-lm'
    CCFLAGS           => '-w',
    INC               => "-I. $gsl_inc", # e.g., '-I. -I/usr/include/other'
	# Un-comment this if you add C files to link with later:
    OBJECT            => 'MITDT.o'
);
