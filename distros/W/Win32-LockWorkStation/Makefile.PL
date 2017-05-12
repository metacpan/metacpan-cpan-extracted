use 5.006001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

# Only supported on Win32
unless ($^O eq "MSWin32" || $^O eq "cygwin") {
    die "OS unsupported\n"
}

# Must be Win32 version greater than 5
#   _WIN32_WINNT must be defined as greater than 5 for 
#   LockWorkStation prototype to be defined in winuser.h.
my $ver = `ver`;
$ver =~ / ([\d\.]+)/;
$ver = $1;

if ($ver < 5) {
    die "OS unsupported\n  Windows version must be greater than 5.\n  Found '$ver' with the 'ver' command."
}

WriteMakefile(
    NAME              => 'Win32::LockWorkStation',
    VERSION_FROM      => 'lib/Win32/LockWorkStation.pm', # finds $VERSION
    ($ExtUtils::MakeMaker::VERSION >= 6.3002) ? ('LICENSE'  => 'perl', ) : (),
    LIBS              => ['-luser32'],
    DEFINE            => '-D_WIN32_WINNT=0x0500',
    PREREQ_PM         => {'Test::Simple' => 0, }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Win32/LockWorkStation.pm', # retrieve abstract from module
       AUTHOR         => 'Michael Vincent <vin at vinsworld dot com>') : ()),
);
