#use 5.008006; # Should work with earlier perls
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Win32::Fmode',
    VERSION_FROM      => 'lib/Win32/Fmode.pm', # finds $VERSION
);

