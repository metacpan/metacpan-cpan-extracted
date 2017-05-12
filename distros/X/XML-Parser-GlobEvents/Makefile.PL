use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'XML::Parser::GlobEvents',
    VERSION_FROM      => 'lib/XML/Parser/GlobEvents.pm', # finds $VERSION
    PREREQ_PM         => { XML::Parser::Expat => 0}, # e.g., Module::Name => 1.1
    ABSTRACT_FROM     => 'lib/XML/Parser/GlobEvents.pod',
    AUTHOR            => 'Bart Lateur <bart.lateur@pandora.be>',
);
