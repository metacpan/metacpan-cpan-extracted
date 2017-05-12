use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Text::AsReadWithoutIntonation',
    VERSION_FROM      => 'lib/Text/AsReadWithoutIntonation.pm', # finds $VERSION
    PREREQ_PM         => {Lingua::ES::Numeros => 0.06, Text::IdMor => 0.01, Text::Roman => 0.01, Symbol::Name => 0.01, String::Multibyte => 0.01}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Text/AsReadWithoutIntonation.pm', # retrieve abstract from module
       AUTHOR         => 'Alberto Montero <amontero@gsi.dit.upm.es>') : ()),
);
