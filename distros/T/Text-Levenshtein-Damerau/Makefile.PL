use 5.008_008; # for utf8, sorry legacy Perls
use strict;
use warnings; 
use ExtUtils::MakeMaker;

my $pm =   'lib/Text/Levenshtein/Damerau.pm';
my $repo = 'https://github.com/ugexe/Text--Levenshtein--Damerau';
my $bugs = 'https://rt.cpan.org/Public/Dist/Display.html?Name=Text-Levenshtein-Damerau';
 
WriteMakefile (  
    NAME => 'Text::Levenshtein::Damerau',
    VERSION_FROM => $pm, 
    ABSTRACT_FROM => $pm,
    AUTHOR => 'Nick Logan <ugexe@cpan.org>',
    LICENSE => 'perl',
    MIN_PERL_VERSION => '5.008008',
    PREREQ_PM => {
	'List::Util'		=> 0,
    },
    BUILD_REQUIRES => {
	'Test::More'		=> 0,
    },
    META_MERGE => {
        resources => {
            repository => $repo, 
            bugtracker => "$bugs",
        },
        provides => {
            'Text::Levenshtein::Damerau' => {
                file    => 'lib/Text/Levenshtein/Damerau.pm',
                version => '0.41',
            },
            'Text::Levenshtein::Damerau::PP' => {
                file    => 'lib/Text/Levenshtein/Damerau/PP.pm',
                version => '0.25',
            },
        },

    },

    depend => { '$(FIRST_MAKEFILE)' => '$(VERSION_FROM)' },
);