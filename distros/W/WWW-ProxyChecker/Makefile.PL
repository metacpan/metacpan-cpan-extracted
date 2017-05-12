use strict;
use warnings;
 
use 5.006;
 
use ExtUtils::MakeMaker 6.30;
 
my %WriteMakefileArgs = (
    "ABSTRACT" => "check whether or not proxy servers are alive",
    "AUTHOR" => "Zoffix Znet <cpan\@zoffix.com>",
    "BUILD_REQUIRES" => {},
    "CONFIGURE_REQUIRES" => {
        "ExtUtils::MakeMaker" => "6.30"
    },
    "DISTNAME" => "WWW-ProxyChecker",
    "EXE_FILES" => [],
    "LICENSE" => "perl",
    "NAME" => "WWW::ProxyChecker",
    "META_MERGE" => {
        'meta-spec' => { version => 2 },
        resources => {
            bugtracker => {
                web => 'https://github.com/stevieb9/p5-www-proxychecker/issues',
            },
            repository => {
                type => 'git',
                url => 'https://github.com/stevieb9/p5-www-proxychecker.git',
                web => 'https://github.com/stevieb9/p5-www-proxychecker',
            },
        },
    },

    "PREREQ_PM" => {
        "Carp" => 0,
        "Class::Accessor::Grouped" => 0,
        "IO::Pipe" => 0,
        "LWP::UserAgent" => 0,
        "WWW::FreeProxyListsCom" => 0,
        "base" => 0,
        "strict" => 0,
        "warnings" => 0
    },
    "TEST_REQUIRES" => {
        "File::Spec" => 0,
        "IO::Handle" => 0,
        "IPC::Open3" => 0,
        "Test::More" => 0
    },
    "VERSION_FROM" => 'lib/WWW/ProxyChecker.pm',
    "test" => {
        "TESTS" => "t/*.t"
    }
);


my %FallbackPrereqs = (
    "Carp" => 0,
    "Class::Accessor::Grouped" => 0,
    "File::Spec" => 0,
    "IO::Handle" => 0,
    "IO::Pipe" => 0,
    "IPC::Open3" => 0,
    "LWP::UserAgent" => 0,
    "Test::More" => 0,
    "base" => 0,
    "strict" => 0,
    "warnings" => 0
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
    delete $WriteMakefileArgs{TEST_REQUIRES};
    delete $WriteMakefileArgs{BUILD_REQUIRES};
    $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);
