use 5.006001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Tk::Airports',
    VERSION_FROM      => 'lib/Tk/Airports.pm', # finds $VERSION
    PREREQ_PM         => {
        Tk           => 804.027,
        Tk::HList    => 0,
        Tk::Toplevel => 0,
        Test::More   => 0.67,
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Tk/Airports.pm', # retrieve abstract from module
       AUTHOR         => 'Renee <module@renee-baecker.de>') : ()),
    ($ExtUtils::MakeMaker::VERSION >= 6.31 ?
      (LICENSE        => 'artistic_2') : ()),
);
