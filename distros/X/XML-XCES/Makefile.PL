use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'XML::XCES',
    AUTHOR              => 'Alberto Simoes <ambs@cpan.org>',
    VERSION_FROM        => 'lib/XML/XCES.pm',
    ABSTRACT_FROM       => 'lib/XML/XCES.pm',
    EXE_FILES           => ['scripts/xces-align2files'],
    PL_FILES            => {},
    PREREQ_PM => {
		  'XML::DT' => 0.37,
		  'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'XML-XCES-*' },
);
