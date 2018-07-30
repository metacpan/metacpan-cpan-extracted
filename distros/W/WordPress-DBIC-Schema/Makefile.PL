use 5.010001;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'WordPress::DBIC::Schema',
    AUTHOR           => q{Marco Pessotto <melmothx@gmail.com>},
    VERSION_FROM     => 'lib/WordPress/DBIC/Schema.pm',
    ABSTRACT_FROM    => 'lib/WordPress/DBIC/Schema.pm',
    LICENSE          => 'perl_5',
    PL_FILES         => {},
    MIN_PERL_VERSION => '5.010001',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    BUILD_REQUIRES => {
        'Test::More' => '0',
    },
    PREREQ_PM => {
                  'DBIx::Class' => 0,
                  'DBIx::Class::Tree' => 0,
                  'DBIx::Class::Helpers' => 0,
                  'DBIx::Class::Schema::Config' => 0,
                  'URI' => 0,
                 },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'WordPress-DBIC-Schema-*' },
);
