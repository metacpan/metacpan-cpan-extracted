use 5.008008;
use ExtUtils::MakeMaker;

die 'OS unsupported! Sorry, but this system seems not to be a Windows system!'
   unless $^O =~ /win32/i;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Win32::FileNotify',
    VERSION_FROM      => 'lib/Win32/FileNotify.pm', # finds $VERSION
    PREREQ_PM         => {
        Carp                => 0,
        File::Basename      => 0,
        Win32::ChangeNotify => 1.05,
        File::stat          => 0,
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Win32/FileNotify.pm', # retrieve abstract from module
       AUTHOR         => 'Renee Baecker <module@renee-baecker.de>') : ()),
    ($ExtUtils::MakeMaker::VERSION >= 6.31 ?
      (LICENSE        => 'perl') : ()),
);
