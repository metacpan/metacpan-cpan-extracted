use strict;
use warnings;
use ExtUtils::MakeMaker;

my %make;
if ($ExtUtils::MakeMaker::VERSION > 6.64) {
   $make{META_MERGE} = {
    'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/JJ/Test-Text.git',
                web  => 'https://github.com/JJ/Test-Text',
            },
        },
    };
}

WriteMakefile(
    NAME                => 'Test::Text',
    AUTHOR              => 'JJ Merelo <jj@merelo.net>',
    VERSION_FROM        => 'lib/Test/Text.pm',
    ABSTRACT_FROM       => 'lib/Test/Text.pm',
    LICENSE => 'gpl',
    PL_FILES            => {},
    PREREQ_PM => {
		  'Test::More' => 0,
		  'version'    => 0,
		  'File::Slurp::Tiny' => 0,
		  'Text::Hunspell' => 2.08,
		  'Test::Simple' => 1.0 #base class 
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Test-Text-*' },
    %make,
);
