use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Test::XMLElement',
    VERSION_FROM      => 'lib/Test/XMLElement.pm', # finds $VERSION
    PREREQ_PM         => {'XML::Twig' => undef, 'XML::XPath' => undef}, # e.g., Module::Name => 1.1
    ABSTRACT_FROM  => 'lib/Test/XMLElement.pm', # retrieve abstract from module
	AUTHOR         =>  'Murugesan Kandasamy <murugu@cpan.org>'
);
