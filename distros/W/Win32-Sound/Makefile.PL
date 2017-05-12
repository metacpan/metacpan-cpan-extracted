use strict;
use warnings;
use ExtUtils::MakeMaker;

unless ($^O eq "MSWin32" || $^O eq "cygwin") {
    die "OS unsupported\n";
}

my %param = (
    NAME          => 'Win32::Sound',
    VERSION_FROM  => 'Sound.pm',
);
$param{NO_META} = 1 if eval "$ExtUtils::MakeMaker::VERSION" >= 6.10_03;
$param{LIBS} = ['-L/lib/w32api -lwinmm'] if $^O eq "cygwin";
WriteMakefile(%param);
