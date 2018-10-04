use strict;
use warnings;
use ExtUtils::MakeMaker;

my $pm = 'lib/Text/Fuzzy.pm';
my $pod = 'lib/Text/Fuzzy.pod';
my $repo = 'https://github.com/benkasminbullock/Text-Fuzzy';

WriteMakefile (
    NAME => 'Text::Fuzzy',
    VERSION_FROM => $pm,
    ABSTRACT_FROM => $pod,
    AUTHOR => 'Ben Bullock <bkb@cpan.org>',
    LICENSE => 'perl',
    PREREQ_PM => {
    },
    META_MERGE => {
        resources => {
            repository => $repo,
            bugtracker => "$repo/issues",
        },
        x_contributors => [
	    'Nick Logan <ugexe@cpan.org>',
        ],
    },
    OBJECT => 'Fuzzy.o',
#    OPTIMIZE => '-Wall -O',
    MIN_PERL_VERSION => '5.008001',
);
