# Only EU::MM 6.52+ understands CONFIGURE_REQUIRES
use ExtUtils::MakeMaker 6.52;
use Alien::Hunspell 0.04;
use Config;

my $CC = $ENV{'CXX'} || 'c++';

my $shlib_location = Alien::Hunspell->libs;
my $header_location = Alien::Hunspell->cflags;

    WriteMakefile(
        NAME          => 'Text::Hunspell',
        VERSION_FROM  => 'Hunspell.pm',
        CCFLAGS       => "$Config{ccflags} $header_location",
        LIBS          => [$shlib_location],
        CC            => $CC,
        LD            => '$(CC)',
        CONFIGURE_REQUIRES => {
            'ExtUtils::MakeMaker' => '6.52',
            'Alien::Hunspell'     => '0.04',
        },
        XSOPT         => '-C++',
        TYPEMAPS      => ['perlobject.map', 'typemap'],
        META_MERGE    => {
            resources => {
                repository => 'https://github.com/cosimo/perl5-text-hunspell',
            },
            keywords  => [ qw(hunspell spelling spell-checker text-processing) ],
        },
    );
