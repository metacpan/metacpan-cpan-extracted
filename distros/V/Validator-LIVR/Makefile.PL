use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

my( $mm ) = $ExtUtils::MakeMaker::VERSION =~ /^([^_]+)/;

WriteMakefile(
    NAME             => 'Validator::LIVR',
    AUTHOR           => q{Viktor Turskyi <koorchik@cpan.org>},
    VERSION_FROM     => 'lib/Validator/LIVR.pm',
    ABSTRACT_FROM    => 'lib/Validator/LIVR.pm',
    LICENSE          => 'Artistic_2_0',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.010,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    BUILD_REQUIRES => {
        'Test::More'      => '0',
        'Test::Exception' => '0',
        'JSON'            => '0'
    },
    PREREQ_PM => {
        'Email::Valid'   => '0',
        'Regexp::Common' => '0'
    },
    ( $mm < 6.46
        ? ()
        : ( META_MERGE => {
              resources => {
                  repository => 'https://github.com/koorchik/Validator-LIVR',
              },
              no_index => {directory => [qw/t/]},
            }
        )
    ),
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Validator-LIVR-*' },
);
