use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'cli::tsv::latextable',
    AUTHOR           => q{"Toshiyuki Shimono" <bin4tsv@gmail.com>},
    VERSION_FROM     => 'lib/cli/tsv/latextable.pm',
    ABSTRACT_FROM    => 'lib/cli/tsv/latextable.pm',
    LICENSE          => 'gpl_3',
    PL_FILES         => {},
    MIN_PERL_VERSION => '5.006',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    BUILD_REQUIRES => {
        'Test::More' => '0',
    },
    PREREQ_PM => {
        #'ABC'              => '1.6',
        #'Foo::Bar::Module' => '5.0401',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'cli-tsv-latextable-*' },
);
