use strict;
use warnings;

use Config;
use ExtUtils::MakeMaker;
use Devel::CheckLib;

check_lib_or_exit(
    lib     => [qw( stree )],
    libpath => [ split ' ', $Config{loclibpth} ],
    header  => 'libstree.h',
    incpath => [ split ' ', $Config{locincpth} ],
);

my %conf = (
    NAME               => 'Tree::Suffix',
    AUTHOR             => 'gray <gray@cpan.org>',
    LICENSE            => 'perl',
    VERSION_FROM       => 'lib/Tree/Suffix.pm',
    ABSTRACT_FROM      => 'lib/Tree/Suffix.pm',
    CONFIGURE_REQUIRES => { 'Devel::CheckLib' => 0 },
    PREREQ_PM          => { XSLoader => 0, },
    BUILD_REQUIRES     => { 'Test::More' => 0 },
    LIBS               => ["-lstree"],
    META_MERGE    => {
        resources => {
            repository => 'http://github.com/gray/tree-suffix',
        },
    },
    dist          => { COMPRESS => 'gzip -9f', SUFFIX => '.gz', },
    clean         => { FILES => 'Tree-Suffix-*' },
);

unless (eval { ExtUtils::MakeMaker->VERSION(6.46) }) {
    delete $conf{META_MERGE};
}

WriteMakefile(%conf);
