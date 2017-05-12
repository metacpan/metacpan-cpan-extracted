use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Transform::Canvas',
    AUTHOR              => 'Ronan Oger <ronan@cpan.org>',
    VERSION_FROM        => 'lib/Transform/Canvas.pm',
    ABSTRACT_FROM       => 'lib/Transform/Canvas.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Carp' => 0,
        'SVG::Parser' => 0.9,
        'Data::Dumper' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Transform-Canvas-*' },
);
