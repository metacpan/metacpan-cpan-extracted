use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Test::JSON::Schema::Acceptance',
    AUTHOR           => q{Ben Hutton (@relequestual) <relequest@cpan.org>},
    VERSION_FROM     => 'lib/Test/JSON/Schema/Acceptance.pm',
    ABSTRACT_FROM    => 'lib/Test/JSON/Schema/Acceptance.pm',
    LICENSE          => 'mit',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.010,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'Test::More' => 1.001,
        'Test::Fatal' => 0.014,
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },

        resources => {
            repository => {
                type => 'git',
                url => 'git@github.com:Relequestual/Test-JSON-Schema-Acceptance.git',
                web => 'https://github.com/Relequestual/Test-JSON-Schema-Acceptance',
            },
            x_IRC => 'irc://irc.perl.org/#json-schema',

        },
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Test-JSON-Schema-Acceptance-*' },
);
