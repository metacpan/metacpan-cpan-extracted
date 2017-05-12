use strict;
use warnings;
use ExtUtils::MakeMaker;

my $pm = 'lib/Unicode/Properties.pm';
my $pod = 'lib/Unicode/Properties.pod';
my $repo = 'https://github.com/benkasminbullock/Unicode-Properties';
WriteMakefile (
    NAME => 'Unicode::Properties',
    VERSION_FROM => $pm,
    ABSTRACT_FROM => $pod,
    AUTHOR => 'Ben Bullock <bkb@cpan.org>',
    PREREQ_PM => {
        'Unicode::UCD' => 0,
        'Test::More' => 0,
    },
    MIN_PERL_VERSION => '5.008009',
    LICENSE => 'perl',
    META_MERGE => {
        resources => {
            repository => $repo,
            bugtracker => "$repo/issues",
        },
    },
);
