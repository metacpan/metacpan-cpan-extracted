use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'XML::Hash',
    AUTHOR        => 'Luis Azevedo <braceta@cpan.org>',
    VERSION_FROM  => 'lib/XML/Hash.pm',
    ABSTRACT_FROM => 'lib/XML/Hash.pm',
    PL_FILES      => {},
    LICENSE       => 'bsd',
    PREREQ_PM     => {
        'Test::More'  => 0.44,
        'Test::XML'   => 0.07,
        'XML::Simple' => 2.18,
        'XML::DOM'    => 1.43,
        'File::Slurp' => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'XML-Hash-*' },
);
