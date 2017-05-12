use strict;
use warnings;
use ExtUtils::MakeMaker;

ExtUtils::MakeMaker->VERSION(6.98) if -f '.gitignore';

my %WriteMakefileArgs = (
    NAME                => 'Text::Glob',
    VERSION_FROM        => 'lib/Text/Glob.pm',
    ABSTRACT_FROM       => 'lib/Text/Glob.pm',
    AUTHOR              => 'Richard Clamp <richardc@unixbeard.net>',
    LICENSE             => 'perl_5',
    MIN_PERL_VERSION    => '5.00503',

    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    PREREQ_PM => {
        'Exporter' => '0',
        'constant' => '0',
    },
    TEST_REQUIRES => {
        'Test::More' => '0',
    },

    META_MERGE => {
        'meta-spec' => { version => 2 },
        dynamic_config => 0,
        resources => {
            bugtracker => {
                mailto => 'richardc@unixbeard.net',
            },
        },
    },
);

# degrade gracefully for older EUMM/older perls

if (!eval { ExtUtils::MakeMaker->VERSION('6.6303') }) {
    $WriteMakefileArgs{BUILD_REQUIRES} = $WriteMakefileArgs{TEST_REQUIRES};
    delete $WriteMakefileArgs{TEST_REQUIRES};
}

if (!eval { ExtUtils::MakeMaker->VERSION('6.5501') }) {
    @{$WriteMakefileArgs{PREREQ_PM}}{ keys %{$WriteMakefileArgs{BUILD_REQUIRES}} } =
        @{$WriteMakefileArgs{BUILD_REQUIRES}}{ keys %{$WriteMakefileArgs{BUILD_REQUIRES}} };

    delete $WriteMakefileArgs{BUILD_REQUIRES};
}

WriteMakefile(%WriteMakefileArgs);
