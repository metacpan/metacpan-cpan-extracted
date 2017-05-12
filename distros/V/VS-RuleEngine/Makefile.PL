#!/usr/bin/perl

use 5.006;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'VS::RuleEngine',
    VERSION_FROM        => 'lib/VS/RuleEngine.pm',
    LICENSE             => 'mit',
    PREREQ_PM           => {
        List::Util              => 0,
        Object::Tiny            => 0,
        Scalar::Util            => 0,
        Test::AbstractMethod    => 0,
        Test::Exception         => 0,
        Test::More              => 0,
    },
    ABSTRACT_FROM       => 'lib/VS/RuleEngine.pm', 
    AUTHOR              => 'Claes Jakobsson <claesjac@cpan.org>',
    test               =>  {TESTS => 't/*/*.t'},
);