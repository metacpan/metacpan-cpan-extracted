use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'XML::Spew',
    AUTHOR              => 'Mike Friedman <friedo@friedo.com>',
    VERSION_FROM        => 'lib/XML/Spew.pm',
    ABSTRACT_FROM       => 'lib/XML/Spew.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'XML-Spew-*' },
);
