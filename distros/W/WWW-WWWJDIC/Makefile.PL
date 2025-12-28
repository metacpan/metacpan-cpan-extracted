use warnings;
use strict;
use ExtUtils::MakeMaker;
my $pm = 'lib/WWW/WWWJDIC.pm';
my $pod = 'lib/WWW/WWWJDIC.pod';
my $repo = 'https://github.com/benkasminbullock/WWW-WWWJDIC';
WriteMakefile (
    NAME => 'WWW::WWWJDIC',
    AUTHOR => 'Ben Bullock <benkasminbullock@gmail.com>',
    VERSION_FROM => $pm,
    ABSTRACT_FROM => $pod,
    LICENSE => 'perl',
    PREREQ_PM => {
	'URI::Escape' => '5.28',
	'JSON::Parse' => '0.62',
    },
    META_MERGE => {
        'meta-spec' => {
            version => 2,
        },
        resources => {
            repository => {
                type => 'git',
                url => "git://$repo.git",
                web => $repo,
            },
            bugtracker => {
                web => "$repo/issues",
            },
#           homepage => 'http://',
        },
    },
    MIN_PERL_VERSION => '5.006001',
);

