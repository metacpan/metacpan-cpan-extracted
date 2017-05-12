use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Text::Statistics::Latin',
    VERSION_FROM      => 'lib/Text/Statistics/Latin.pm', # finds $VERSION
    PREREQ_PM         => {Text::ParseWords => 3.1,}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Text/Statistics/Latin.pm', # retrieve abstract from module
       AUTHOR         => 'Rdorigo Panchiniak Fernandes <fernandes@cpan.org>') : ()),
);
