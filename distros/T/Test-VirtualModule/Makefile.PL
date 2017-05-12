use strict;
use warnings;
use 5.008001;

use ExtUtils::MakeMaker 6.30;

my %WriteMakefileArgs = (
    ABSTRACT => "Virtual modules mechanism for unit tests.",
    AUTHOR => "justnoxx",
    BUILD_REQUIRES => {},
    CONFIGURE_REQUIRES => {
        "ExtUtils::MakeMaker" => "6.30",
    },
    DISTNAME => "Test-VirtualModule",
    LICENSE => "perl",
    NAME => "Test::VirtualModule",
    PREREQ_PM => {
        "POSIX" =>  0,
        "Carp"  =>  0
    },
    VERSION_FROM => "lib/Test/VirtualModule.pm",
    test => {
        "TESTS" => "t/*.t"
    },
    dist  => {
        COMPRESS => 'gzip -9f',
        SUFFIX => 'gz',
    },
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
    my $tr = delete $WriteMakefileArgs{TEST_REQUIRES};
    my $br = $WriteMakefileArgs{BUILD_REQUIRES};
    for my $mod ( keys %$tr ) {
        if ( exists $br->{$mod} ) {
            $br->{$mod} = $tr->{$mod} if $tr->{$mod} > $br->{$mod};
        }
        else {
            $br->{$mod} = $tr->{$mod};
        }
    }
}

unless ( eval { ExtUtils::MakeMaker->VERSION(6.56) } ) {
    my $br = delete $WriteMakefileArgs{BUILD_REQUIRES};
    my $pp = $WriteMakefileArgs{PREREQ_PM};
    for my $mod ( keys %$br ) {
        if ( exists $pp->{$mod} ) {
            $pp->{$mod} = $br->{$mod} if $br->{$mod} > $pp->{$mod};
        }
        else {
            $pp->{$mod} = $br->{$mod};
        }
    }
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES} unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

# if so, ExtUtils::MakeMaker supports META_MERGE tag
if ($ExtUtils::MakeMaker::VERSION >= 6.46) {
    $WriteMakefileArgs{META_MERGE} = {
        "meta-spec" => { version => 2 },
        resources => {
            repository => {
                type    => 'git',
                url     => 'https://github.com/justnoxx/test-virtualmodule',
                web     => 'https://github.com/justnoxx/test-virtualmodule.git',
            },
        },
    };
}

WriteMakefile(%WriteMakefileArgs);
