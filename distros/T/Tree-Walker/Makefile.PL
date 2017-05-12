use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Tree::Walker',
    AUTHOR           => q{Michael Roberts <michael@vivtek.com>},
    VERSION_FROM     => 'lib/Tree/Walker.pm',
    ABSTRACT_FROM    => 'lib/Tree/Walker.pm',
    LICENSE          => 'Artistic_2_0',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        #'ABC'              => 1.6,
        #'Foo::Bar::Module' => 5.0401,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Tree-Walker-*' },
    META_MERGE => {
      'meta-spec' => { version => 2 },
       resources => {
          repository => {
             type => 'git',
             url  => 'https://github.com/Vivtek/Tree-Walker.git',
             web  => 'https://github.com/Vivtek/Tree-Walker',
          },
       },
    },
);
