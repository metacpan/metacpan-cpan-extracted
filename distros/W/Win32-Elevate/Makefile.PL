use 5.018000;
use strict;
use warnings;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

unless ($^O eq "MSWin32" || $^O eq "cygwin") {
    die "OS unsupported\n";
}

WriteMakefile(
    NAME              => 'Win32::Elevate',
    VERSION_FROM      => 'lib/Win32/Elevate.pm', # finds $VERSION, requires EU::MM from perl >= 5.5
    PREREQ_PM         => {Win32 => 0.27_01}, # e.g., Module::Name => 1.1
    ABSTRACT_FROM     => 'lib/Win32/Elevate.pm', # retrieve abstract from module
    AUTHOR            => 'Daniel Just',
    LICENSE           => 'perl',
    #Value must be from legacy list of licenses here
    #https://metacpan.org/pod/Module::Build::API
    LIBS              => [''], # e.g., '-lm'
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => '-I.', # e.g., '-I. -I/usr/include/other'
	# Un-comment this if you add C files to link with later:
    # OBJECT            => '$(O_FILES)', # link all the C files too
);
