use strict;
use warnings;
use ExtUtils::MakeMaker;

my $name = 'Unicode::Diacritic::Strip';
my $pm = 'lib/Unicode/Diacritic/Strip.pm';
my $pod = 'lib/Unicode/Diacritic/Strip.pod';
my $repo = "https://github.com/benkasminbullock/Unicode-Diacritic-Strip";
$repo =~ s!::!-!g;

WriteMakefile (
    NAME => $name,
    VERSION_FROM => $pm,
    ABSTRACT_FROM => $pod,
    AUTHOR => 'Ben Bullock <bkb@cpan.org>',
    LICENSE => 'perl',
    PREREQ_PM => {
	'Unicode::UCD' => '0',
    },
    META_MERGE => {
        resources => {
            repository => $repo,
            bugtracker => "$repo/issues",
        },
    },
    MIN_PERL_VERSION => '5.008009',
    EXE_FILES => ['./script/critstrip',],
);
