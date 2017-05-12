use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Text::WrapProp',
    LICENSE           => 'perl_5',
    VERSION_FROM      => 'lib/Text/WrapProp.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    TEST_REQUIRES     => {
                           Test::More => 0,
                         },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Text/WrapProp.pm', # retrieve abstract from module
       AUTHOR         => 'James Briggs <james.briggs@yahoo.com>') : ()),
);
