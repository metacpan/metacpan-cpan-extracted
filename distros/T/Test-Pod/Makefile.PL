use strict;
use warnings;
require 5.008;
use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
    NAME                => 'Test::Pod',
    VERSION_FROM        => 'lib/Test/Pod.pm',
    ABSTRACT_FROM       => 'lib/Test/Pod.pm',
    AUTHOR              => 'David E. Wheeler <david@justatheory.com>',
    LICENSE             => 'perl_5',

    META_MERGE => {
        'meta-spec' => { version => 2 },
        dynamic_config => 0,
        resources => {
            homepage => 'http://search.cpan.org/dist/Test-Pod/',
            license => ['http://dev.perl.org/licenses/'],
            repository => {
                url => 'https://github.com/perl-pod/test-pod.git',
                web => 'https://github.com/perl-pod/test-pod',
                type => 'git',
            },
            bugtracker => {
                web => 'http://github.com/perl-pod/test-pod/issues/',
            },
        },
        x_MailingList => 'http://lists.perl.org/list/pod-people-qa.html',
        x_IRC => 'irc://irc.perl.org/#perl-qa', # maybe we should make a pod channel?
        x_contributors => [ # manually added, from git shortlog -e -s -n
            'David E. Wheeler <david@justatheory.com>',
            'Andy Lester <andy@petdance.com>',
            'Paul Miller <jettero@cpan.org>',
            'Luca Ferrari <fluca1978@gmail.com>',
            'Karen Etheridge <ether@cpan.org>',
            'ChrisWi <chris@computersalat.de>',
            'David Steinbrunner <dsteinbrunner@pobox.com>',
        ],
    },

    META_ADD => {
        'meta-spec' => { version => 2 },
        prereqs => {
            configure => {
                requires => {
                    'ExtUtils::MakeMaker' => '0',
                },
            },
            runtime => {
                requires => {
                    'perl'                  => '5.008',
                    'File::Find'            => '0',
                    'Pod::Simple'           => '3.05',
                    'Test::Builder::Tester' => '1.02',
                    'Test::More'            => '0.62',
                },
            },
            test => {
                requires => {
                    'File::Spec'    => '0',
                    'Pod::Simple'   => '3.05',
                    'Test::More'    => '0.62',
                },
            },
        },
    },
);

my $developer = -f '.gitignore';
if ($developer) {
    ExtUtils::MakeMaker->VERSION('6.98');
    require ExtUtils::Manifest;
    ExtUtils::Manifest->VERSION('1.70');
    $WriteMakefileArgs{NORECURS} = 1;
}


my $eumm_version  = eval $ExtUtils::MakeMaker::VERSION;
ExtUtils::MakeMaker->VERSION(6.98) if $developer;

for (qw(configure build test runtime)) {
    my $key = $_ eq 'runtime' ? 'PREREQ_PM' : uc $_.'_REQUIRES';
    next unless exists $WriteMakefileArgs{META_ADD}{prereqs}{$_}
             or exists $WriteMakefileArgs{$key};
    my $r = $WriteMakefileArgs{$key} = {
        %{$WriteMakefileArgs{META_ADD}{prereqs}{$_}{requires} || {}},
        %{delete $WriteMakefileArgs{$key} || {}},
    };
    defined $r->{$_} or delete $r->{$_} for keys %$r;
}

# dynamic prereqs get added here.

$WriteMakefileArgs{MIN_PERL_VERSION} = delete $WriteMakefileArgs{PREREQ_PM}{perl} || 0;

die 'attention developer: you need to do a sane meta merge here!'
    if keys %{$WriteMakefileArgs{BUILD_REQUIRES}};

$WriteMakefileArgs{BUILD_REQUIRES} = {
    %{$WriteMakefileArgs{BUILD_REQUIRES} || {}},
    %{delete $WriteMakefileArgs{TEST_REQUIRES}}
} if $eumm_version < 6.63_03;

$WriteMakefileArgs{PREREQ_PM} = {
    %{$WriteMakefileArgs{PREREQ_PM}},
    %{delete $WriteMakefileArgs{BUILD_REQUIRES}}
} if $eumm_version < 6.55_01;

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
    if $eumm_version < 6.51_03;

delete $WriteMakefileArgs{MIN_PERL_VERSION}
    if $eumm_version < 6.48;

delete @WriteMakefileArgs{qw(META_ADD META_MERGE)}
    if not $developer;

delete $WriteMakefileArgs{LICENSE}
    if $eumm_version < 6.31;

WriteMakefile(%WriteMakefileArgs);
