use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'WebService::JotForm',
    AUTHOR           => q{Tim Vroom <vroom@blockstackers.com>},
    VERSION_FROM     => 'lib/WebService/JotForm.pm',
    ABSTRACT_FROM    => 'lib/WebService/JotForm.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
    },
    TEST_REQUIRES => {
        'Test::More'	=> 0,
		'Test::Deep' 	=> 0,
    },
    PREREQ_PM => {
	'Carp' 				=> 0,
	'Moo'  				=> 0,
	'JSON::MaybeXS' 	=> 0,
	'LWP::UserAgent' 	=> 0,
	'URI::Escape'		=> 0,
    },
    META_MERGE => {
    'meta-spec' => { version => 2 },
         resources => {
             repository => {
                type => 'git',
                url  => 'https://github.com/tvroom/WebService-JotForm',
                web  => 'https://github.com/tvroom/WebService-JotForm.git',
             },
         },
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'WebService-JotForm-*' },
);
