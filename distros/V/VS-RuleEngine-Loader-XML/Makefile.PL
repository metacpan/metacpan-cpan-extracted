#!perl

use 5.006;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'VS::RuleEngine::Loader::XML',
    VERSION_FROM        => 'lib/VS/RuleEngine/Loader/XML.pm',
    LICENSE             => 'MIT',
    PREREQ_PM           => {
        VS::RuleEngine      => 0.08,
        Object::Tiny        => 0,
        Scalar::Util        => 0,
        Test::Exception     => 0,
        Test::More          => 0,
        XML::LibXML         => 0,
    },
    ABSTRACT_FROM       => 'lib/VS/RuleEngine/Loader/XML.pm', 
    AUTHOR              => 'Claes Jakobsson <claesjac@cpan.org>',
);