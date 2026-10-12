use ExtUtils::MakeMaker;
use strict;
use warnings;

my %WriteMakefileArgs = (
    NAME                => 'singleton',
    VERSION_FROM        => 'lib/singleton.pm',
    AUTHOR              => 'Ivan Trunaev',
    ABSTRACT            => 'signleton - class realised singleton constructor',
    INSTALLDIRS         => ($] < 5.011 ? 'perl' : 'site'),
    PREREQ_PM           => {
        'Test::Simple' => 0.44,
    },
    ( eval { ExtUtils::MakeMaker->VERSION(6.46) } ? () : ( META_MERGE => {
        'meta-spec' => { version => 2 },
        dynamic_config => 1,
    })),
);

WriteMakefile(%WriteMakefileArgs);
