use 5.008_008;
use strict;
use warnings;
use ExtUtils::MakeMaker;

my $pm =   'lib/Text/Levenshtein/Damerau/XS.pm';
my $repo = 'https://github.com/ugexe/Text--Levenshtein--Damerau--XS';
my $bugs = 'https://rt.cpan.org/Public/Dist/Display.html?Name=Text-Levenshtein-Damerau-XS';

WriteMakefile ( 
    NAME => 'Text::Levenshtein::Damerau::XS',
    VERSION_FROM => $pm,
    ABSTRACT_FROM => $pm,
    AUTHOR => 'Nick Logan <ugexe@cpan.org>',
    LICENSE => 'perl',
    MIN_PERL_VERSION => '5.008008',
    BUILD_REQUIRES => {
        'CPAN::Meta::Requirements' => '2.120920',
    },
    TEST_REQUIRES => {
        'Test::More' => '0',
    },
    META_MERGE => {
        resources => {
            repository => $repo,
            bugtracker => $bugs,
        },
        provides => {
            'Text::Levenshtein::Damerau::XS' => {
                file    => 'lib/Text/Levenshtein/Damerau/XS.pm',
                version => '3.2',
            },
        },
    },
    depend => { '$(FIRST_MAKEFILE)' => '$(VERSION_FROM)' },
);



# Remove the Makefile dependency. Causes problems on a few systems.
sub MY::makefile { '' }
