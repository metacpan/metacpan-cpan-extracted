# @(#) $Id: Makefile.PL,v 1.9 2007/10/17 14:06:22 mxp Exp $

use 5.006;
use ExtUtils::MakeMaker;
use Config;
use File::Spec;

my %config;
my $ok;
my $devnull = File::Spec->devnull();

###############################################################################
# Read settings from the commandline
# We must delete the options we're handling ourselves to keep
# MakeMaker from processing them, but the rest should be preserved so
# that we get the default MakeMaker behavior.

my $i = 0;

while ($i <= $#ARGV)
{
   my ($key, $val) = split(/=/, $ARGV[$i], 2);
   $config{$key} = $val;

   if ($key eq 'LIBS' || $key eq 'INC')
   {
      delete $ARGV[$i];
   }

   $i++;
}

###############################################################################
# Check for iconv.

if ($config{LIBS} or $config{INC})
{
   print "Your settings:\n",
       "  LIBS: ", $config{LIBS}, "\n", "  INC:  ", $config{INC}, "\n";
}

print 'Checking for iconv ... ';

if (linktest($config{LIBS}, $config{INC}))
{
   $ok = 1;
   print "ok (iconv apparently in libc)\n";
}
elsif ($config{LIBS} !~ /-liconv/)
{
   $config{LIBS} .= ' -liconv';

   if (linktest($config{LIBS}, $config{INC}))
   {
      $ok = 1;
      print "ok (added -liconv)\n";
   }
}

if ($ok)
{
   print <<EOT;

NOTE: If you have multiple iconv implementations installed, you might
      want to make sure that I've found the one you want to use.
      If necessary, you can explicitly specify paths like this:

      $^X Makefile.PL LIBS='-L/path/to/lib' INC='-I/path/to/include'

EOT
}
else
{
   print "fail\n";

   print "Failed to find iconv, please check your settings and re-run as:\n";
   print "$^X Makefile.PL LIBS='-L/path/to/lib' INC='-I/path/to/include'\n";
   exit 1;
}

###############################################################################
# Write the makefile

WriteMakefile(
	      'NAME'              => 'Text::Iconv',
	      'VERSION_FROM'      => 'Iconv.pm', # finds $VERSION
	      'PREREQ_PM'         => {}, # e.g., Module::Name => 1.1
	      ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
	       (ABSTRACT_FROM => 'Iconv.pm', # retrieve abstract from module
		AUTHOR        => 'Michael Piotrowski <mxp@dynalabs.de>') : ()),
	      'LIBS'              => $config{LIBS},
	      'DEFINE'            => "@DEFINE",
	      'INC'               => $config{INC},
	      'dist'              => {COMPRESS => 'gzip', SUFFIX => 'gz'},
	     );

###############################################################################

sub linktest
{
   my $libs = shift;
   my $incs = shift;

   my $file = 'linktest';
   my $obj_ext = $Config{_o};

   my $prog = <<EOT;
#include <iconv.h>

int main(void)
{
   (void) iconv_open("", "");
}
EOT

   my $compile;

   unless ($^O eq 'VMS')
   {
      # It is admittedly a bit simplistic to simply concatenate all
      # flags, but it seems to work in most cases.
      $compile = join ' ', $Config{cc}, $incs, $Config{ccflags},
	  $Config{ldflags}, $libs;
   }
   else
   {
      $compile = join ' ', $Config{cc}, $incs, $Config{ccflags}, $libs;
   }

   if (exists $config{verbose})
   {
      print "\nCompiler: '$compile'\n";
   }

   open  LINKTEST, '>', "$file.c" or die "Can't create test file '$file.c'.";
   print LINKTEST $prog;
   close LINKTEST;

   my $compile_line = "$compile -o $file $file.c $libs 2> $devnull";

   if ($^O eq 'VMS')
   {
      $compile_line = "pipe $compile $file.c $libs 2> NL:";
   }

   if (exists $config{verbose})
   {
      print "\nCompiler command line: '$compile_line'\n";
   }

   my $result = system($compile_line) / 256;
   unlink $file, "$file.c", "$file$obj_ext";

   if ($result == 0)
   {
      return 1;
   }
   else
   {
      return 0;
   }
}
