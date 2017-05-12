use strict;
use warnings;
use ExtUtils::MakeMaker;

my @scripts = grep {-f && !/~/ } glob("scripts/*"); # Ripped from Text::PDF

my %make;
if ($ExtUtils::MakeMaker::VERSION > 6.64) {
   $make{META_MERGE} = {
       'meta-spec' => { version => 2 },
       resources => {
	   repository => {
	       type => 'git',
	       url  => 'https://github.com/JJ/net-citations-scraper.git',
	       web  => 'https://github.com/JJ/net-citations-scraper',
	   },
       },
   };
}

WriteMakefile(
    NAME                => 'Web::Scraper::Citations',
    AUTHOR              => 'JJ <JMERELO@cpan.org>',
    VERSION_FROM        => 'lib/Web/Scraper/Citations.pm',
    ABSTRACT_FROM       => 'lib/Web/Scraper/Citations.pm',
    EXE_FILES => \@scripts,
    LICENSE => 'gpl',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'version'    => 0,
	'Mojo::DOM'  => 0,
	'Mojo::UserAgent' => 0,
	'Moose' => 0,
	'File::Slurp::Tiny' => 0
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Web-Scraper-Citations-*' },
);
