use strict;
use warnings;
use Config;
use ExtUtils::MakeMaker;
use Alien::pugixml;

# CCFLAGS *replaces* $Config{ccflags} in the generated Makefile rather than
# adding to it, and perl's own flags are not optional here: -fno-strict-aliasing
# (perl's headers type-pun SV/AV/HV deliberately, which -O2 would otherwise be
# entitled to miscompile), -D_LARGEFILE_SOURCE/-D_FILE_OFFSET_BITS=64 (they fix
# the ABI of structs this XS shares with libperl), -fwrapv, and the hardening
# defines. Carry them across, dropping the C-only dialect/warning flags that a
# C++ compiler rejects.
my $c_only = qr{^-(?:
      std=(?:gnu|c)[0-9]+
    | W(?:error=)?(?: declaration-after-statement | nested-externs
                    | old-style-definition   | strict-prototypes
                    | missing-prototypes     | implicit-function-declaration
                    | pointer-sign           | bad-function-cast
                    | c\+\+-compat )
)$}x;

my $ccflags = join ' ',
    ( grep { !/$c_only/ } split ' ', $Config{ccflags} ),
    '-std=c++11', '-Wall', Alien::pugixml->cflags;

WriteMakefile(
    NAME             => 'XML::PugiXML',
    VERSION_FROM     => 'lib/XML/PugiXML.pm',
    ABSTRACT         => 'Perl binding for pugixml C++ XML parser',
    AUTHOR           => 'vividsnow',
    LICENSE          => 'perl_5',
    MIN_PERL_VERSION => '5.010',

    CC               => 'c++',
    LD               => 'c++',
    XSOPT            => '-C++',

    CCFLAGS          => $ccflags,
    OPTIMIZE         => '-O2',

    INC              => '-I.',
    LIBS             => [ Alien::pugixml->libs ],

    clean            => { FILES => 'PugiXML.c' },

    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
        'Alien::pugixml'      => '0.03',
    },
    BUILD_REQUIRES => {
        'Alien::pugixml' => '0.03',
    },
    PREREQ_PM => {},
    TEST_REQUIRES => {
        'Test::More' => 0,
    },

    META_MERGE => {
        'meta-spec' => { version => 2 },
        provides    => {
            'XML::PugiXML' => {
                file    => 'lib/XML/PugiXML.pm',
                version => MM->parse_version('lib/XML/PugiXML.pm'),
            },
        },
        resources   => {
            repository => {
                type => 'git',
                url  => 'git://github.com/vividsnow/perl5-xml-pugixml.git',
                web  => 'https://github.com/vividsnow/perl5-xml-pugixml',
            },
            bugtracker => {
                web => 'https://github.com/vividsnow/perl5-xml-pugixml/issues',
            },
        },
    },
);
