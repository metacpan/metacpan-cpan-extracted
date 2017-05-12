use 5.008000;
use ExtUtils::MakeMaker;

#
# test if disasm is installed!
#

unless (have_disasm()) {
  print STDERR <<DEATH;
libdisasm not found.
Please install libdisasm from http://bastard.sourceforge.net/libdisasm.html
DEATH
exit 0; # 0 recommended by http://cpantest.grango.org (Notes for CPAN Authors)
}

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'X86::Disasm',
    VERSION_FROM      => 'lib/X86/Disasm.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/X86/Disasm.pm', # retrieve abstract from module
       AUTHOR         => 'Bob Wilkinson <bob@fourtheye.org>') : ()),
    LIBS              => ['-ldisasm'], # e.g., '-lm'
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => '-I.', # e.g., '-I. -I/usr/include/other'
	# Un-comment this if you add C files to link with later:
    # OBJECT            => '$(O_FILES)', # link all the C files too
);

# below shamelessly stolen from XML::LibXMLs Makefile.PL

use Config;
#use Cwd;
#use Symbol;
use File::Spec;

use vars qw/$DEVNULL/;

BEGIN {
  $DEVNULL = eval { File::Spec->devnull };
  if ($@) { $DEVNULL = '/dev/null' }
}

sub rm_fr {
  my @files = @_;
  my @realfiles;
  foreach (@files) {
    push @realfiles, glob($_);
  }
  foreach my $file (@realfiles) {
    if (-d $file) {
      rm_fr("$file/*");
      rm_fr("$file/.exists");
      rmdir($file) || die "Couldn't remove $file: $!";
    } else {
      chmod(0777, $file);
      unlink($file);
    }
  }
}

sub xsystem {
  my $command = shift;
  if ($DEBUG) {
    print $command, "\n";
    if (system($command) != 0) {
      die "system call to '$command' failed";
    }
    return 1;
  }
  open(OLDOUT, ">&STDOUT");
  open(OLDERR, ">&STDERR");
  open(STDOUT, ">$DEVNULL");
  open(STDERR, ">$DEVNULL");
  my $retval = system($command);
  open(STDOUT, ">&OLDOUT");
  open(STDERR, ">&OLDERR");
  if ($retval == -1) {
    die "system call to '$command' failed";
  }
  return !($? >> 8);
}

sub have_disasm {
  unless (mkdir(".testlink", 0777)) {
    rm_fr(".testlink");
    mkdir(".testlink", 0777) or die "Cannot create .testlink dir: $!";
  }
  chdir (".testlink");

  open(CFILE, ">mytest.c") or die "Can't open temporary file, $!";
  print CFILE <<EOF;
#include <stdio.h>
#include <libdis.h>
int main()
{
  x86_insn_t insn;
  x86_init(opt_none, NULL, NULL);
  return 0;
}
EOF

  my $retval = xsystem(join (" ", $Config{ccname}, $Config{ccflags}, "-o mytest mytest.c -ldisasm"));
  chdir ("..");
  rm_fr(".testlink");
  return $retval;
}
