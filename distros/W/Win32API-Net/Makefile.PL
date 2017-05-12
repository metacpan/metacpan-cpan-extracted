use strict;
use warnings;
use ExtUtils::MakeMaker;

unless ($^O eq "MSWin32" || $^O eq "cygwin") {
    die "OS unsupported\n";
}

my %param = (
    NAME          => 'Win32API::Net',
    VERSION_FROM  => 'Net.pm',
);
$param{LIBS} = ['-L/lib/w32api -lnetapi32'] if $^O eq "cygwin";
$param{NO_META} = 1 if eval "$ExtUtils::MakeMaker::VERSION" >= 6.10_03;
WriteMakefile(%param);

