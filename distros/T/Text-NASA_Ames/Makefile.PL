use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
use 5.006;

WriteMakefile(
    'NAME'		=> 'Text::NASA_Ames',
    'VERSION_FROM'	=> 'lib/Text/NASA_Ames.pm', # finds $VERSION
    'PREREQ_PM'		=> {Class::Accessor => 0.1}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'lib/Text/NASA_Ames.pm', # retrieve abstract from module
       AUTHOR     => 'Heiko Klein <H.Klein@met.no>') : ()),
);
