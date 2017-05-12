use 5.008008;
use ExtUtils::MakeMaker;

use strict;
use warnings;
use Config;

#use Data::Dumper;
#map {$Config{$_} and $Config{$_} =~ /MD/ and print "$_ = $Config{$_}\n"} keys %Config;

my $CCFLAGS = $Config{ccflags};
my $OPTIMIZE = $Config{optimize};
$CCFLAGS =~ s/MD/MT/;
$OPTIMIZE =~ s/MD/MT/;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Win32::Monitoring::WindowPing',
    VERSION_FROM      => 'WindowPing.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ABSTRACT_FROM  => 'WindowPing.pm', # retrieve abstract from module
    AUTHOR         => 'Roman Plessl (rplessl at cpan dot org)',
    INC               => '-I.', # e.g., '-I. -I/usr/include/other',
    CCFLAGS           => $CCFLAGS,
    OPTIMIZE          => $OPTIMIZE,
    LIBS              => [':nosearch -luser32 -lsecur32 -lmsvcrt -lpsapi'],
#     LIBS              => ':nosearch kernel32.lib user32.lib psapi.lib libcmt.lib',
    # Un-comment this if you add C files to link with later:
    # OBJECT          => '$(O_FILES)', # link all the C files too
);
