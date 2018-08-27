use ExtUtils::MakeMaker;

require 5.006;

my %conf = (
    NAME          => 'Time::Warp',
    AUTHOR        => 'Joshua Nathaniel Pritikin <jpritikin@pobox.com>',
    VERSION_FROM  => 'Warp.pm',
    ABSTRACT_FROM => 'Warp.pm',
    LICENSE       => 'perl',
    OBJECT        => 'Warp.o',
    OPTIMIZE      => '-g',
    PREREQ_PM     => {
        'Test::More' => '1.00',
    },
);

if (eval { ExtUtils::MakeMaker->VERSION(6.46) }) {
    $conf{META_MERGE} = {
        'meta-spec' => { version => 2 },
        resources   => {
            repository => {
                type    => 'git',
                url     => 'http://github.com/manwar/Time-Warp.git',
                web     => 'http://github.com/manwar/Time-Warp',
                license => 'http://dev.perl.org/licenses/',
            },
            bugtracker => {
                web => 'http://github.com/manwar/Time-Warp',
            },
        },
    };
}

WriteMakefile(%conf);
