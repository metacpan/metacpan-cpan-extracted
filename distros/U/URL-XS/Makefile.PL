use 5.026000;
use ExtUtils::MakeMaker;
use Config;

WriteMakefile(
    NAME              => 'URL::XS',
    ABSTRACT_FROM     => 'lib/URL/XS.pm',
    VERSION_FROM      => 'lib/URL/XS.pm',
    MIN_PERL_VERSION  => '5.26.0',
    PREREQ_PM         => {'XSLoader' => 0,},
    AUTHOR            => 'Peter P. Neuromantic <p.brovchenko@protonmail.com>',
    LICENSE           => 'mit',
    LIBS              => '',
    DEFINE            => '',
    INC               => '-Isrc',
    OBJECT            => '$(O_FILES)',
    CCFLAGS           => ( $Config{ccflags} // '' ) . ' -Wall -Wextra -std=c11',
    OPTIMIZE          => '-O3 -march=native',
    META_MERGE        => {
        'meta-spec' => {
            version => 2
        },
        resources   => {
            bugtracker => {
                web => 'https://github.com/ChaoticEvil/p5-url-xs/issues'
            },
            repository => {
                type => 'git',
                url  => 'https://github.com/ChaoticEvil/p5-url-xs.git',
                web  => 'https://github.com/ChaoticEvil/p5-url-xs',
            },
        },
    },
);
