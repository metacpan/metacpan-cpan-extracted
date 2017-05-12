use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

my %params = (
    NAME             => 'Text::Spintax',
    AUTHOR           => q{Dale Evans <dale.evans@mycanadapayday.com>},
    VERSION_FROM     => 'lib/Text/Spintax.pm',
    ABSTRACT_FROM    => 'lib/Text/Spintax.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
        'Test::Kwalitee::Extra' => 0,
    },
    PREREQ_PM => {
        'Parse::Lex' => "2.20",
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Text-Spintax-*' },
    META_MERGE => {
        "meta-spec" => { version => 2 },
        provides => ["Text::Spintax","Text::Spintax::RenderNode"],
        resources => {
            repository => {
		type => "git",
		url => "https://github.com/daleevans/Text-Spintax.git",
		web => "https://github.com/daleevans/Text-Spintax",
	    },
	},
    }
);

WriteMakefile(%params);
