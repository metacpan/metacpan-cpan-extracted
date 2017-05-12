use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'WWW::HyperGlossary',
    AUTHOR              => 'Roger A Hall <rogerhall@cpan.org>',
    VERSION_FROM        => 'lib/WWW/HyperGlossary.pm',
    ABSTRACT            => 'Online HyperGlossary for Education',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'        => 0,
        'version'           => 0,
        'Class::Std'        => 0.0.9,
        'Class::Std::Utils' => 0.0.3,
        'YAML'              => 0.68,
        'Carp'              => 1.03,
        'LWP::Simple'       => 1.41,
        'DBIx::MySperql'    => 1.0.1,
        'Digest::MD5'       => 2.36,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'WWW-HyperGlossary-*' },
);
