use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'XML::Trivial',
    AUTHOR              => 'Jan Poslusny <pajout@cpan.org>',
    LICENSE             => 'perl',
    VERSION_FROM        => 'lib/XML/Trivial.pm',
    ABSTRACT_FROM       => 'lib/XML/Trivial.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'         => '>= 0.62',
	'XML::Parser::Expat' => '>= 2.34',
	'Scalar::Util'       => '>= 1.18'
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'XML-Trivial-*' },
);
