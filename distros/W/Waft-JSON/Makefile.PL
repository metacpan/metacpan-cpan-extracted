use 5.005;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Waft::JSON',
    VERSION_FROM      => 'lib/Waft/JSON.pm', # finds $VERSION
    PREREQ_PM         => { # e.g., Module::Name => 1.1
        Waft => 0.9907,
        JSON => 2.15,
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Waft/JSON.pm', # retrieve abstract from module
       AUTHOR         => 'Shingo Murata <murata@cpan.org>') : ()),
);
