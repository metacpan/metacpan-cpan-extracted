use 5.010000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
#
WriteMakefile(
    NAME              => 'Win32::Watir',
    VERSION_FROM      => 'lib/Win32/Watir.pm', # finds $VERSION
    PREREQ_PM         => {
        'Win32'      => 0,
        'Win32::OLE' => 0,
        'Config'     => 0,
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Win32/Watir.pm', # retrieve abstract from module
       AUTHOR         => 'Kazuhito Shimizu <kazuhito.shimizu@gmail.com>') : ()),
);

