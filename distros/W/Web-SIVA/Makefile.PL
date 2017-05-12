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
                url  => 'https://github.com/JJ/perl5-web-siva.git',
                web  => 'https://github.com/JJ/perl5-web-siva',
            },
        },
    };
}

WriteMakefile(
    NAME                => 'Web::SIVA',
    AUTHOR              => 'JJ <JMERELO@cpan.org>',
    VERSION_FROM        => 'lib/Web/SIVA.pm',
    ABSTRACT_FROM       => 'lib/Web/SIVA.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
	    'version'    => 0,
	    'Mojolicious' => 7.13,
	    'LWP::Simple' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Web-SIVA-*' },
);
