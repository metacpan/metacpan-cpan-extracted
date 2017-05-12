use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'WWW::MelbourneBikeShare',
    AUTHOR           => q{Luke Poksitt <ltp@cpan.org>},
    VERSION_FROM     => 'lib/WWW/MelbourneBikeShare.pm',
    ABSTRACT_FROM    => 'lib/WWW/MelbourneBikeShare.pm',
    LICENSE          => 'Artistic_2_0',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More'	=> 0,
    },
    PREREQ_PM => {
	'JSON'		=> 0,
	'LWP'		=> 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'WWW-MelbourneBikeShare-*' },
);
