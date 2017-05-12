use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Text::Mining',
    AUTHOR              => 'Roger A Hall <rogerhall@cpan.org>',
    ABSTRACT            => 'Perl Tools for Text Mining Research',
    VERSION_FROM        => 'lib/Text/Mining.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'        => 0,
        'version'           => 0,
        'Class::Std'        => 0.0.9,
        'Class::Std::Utils' => 0.0.3,
        'YAML'              => 0.68,
        'Carp'              => 1.03,
        'LWP::Simple'       => 1.41,
        'Time::HiRes'       => 1.9715,
        'DBIx::MySperqlOO'  => 1.0.1,
        'File::Spec'        => 3.25,
        'Module::Runtime'   => 0.005,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Text-Mining-*' },
);
