use 5.006;
use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'xDT::Parser',
    VERSION_FROM => 'lib/xDT/Parser.pm',
    ABSTRACT     => 'Perl xDT Parser',
    AUTHOR       => 'Christoph Beger <christoph.beger@medizin.uni-leipzig.de>',
    LICENSE      => 'MIT',
    META_MERGE   => {
        dynamic_config => 0,
        'meta-spec'    => { version   => 2 },
        no_index       => { directory => [ qw(examples t config) ], },
        prereqs        => { runtime   => { requires => { perl => '5.006' } } },
        resources      => {
            bugtracker => { web => 'https://github.com/ChristophB/perl-xdt-parser/issues' },
            license    => [ 'https://opensource.org/licenses/MIT' ],
            repository => {
                type => 'git',
                url  => 'https://github.com/ChristophB/perl-xdt-parser.git',
                web  => 'https://github.com/ChristophB/perl-xdt-parser',
            },
        },
    },
    CONFIGURE_REQUIRES => { 'ExtUtils::MakeMaker' => '7.44' },
    TEST_REQUIRES      => { 'Test::More' => '1.3', 'JSON::Parse' => '>=0.59' },
    PREREQ_PM          => { 'Moose' => '2', 'XML::Simple' => '2.25' },
    test  => { TESTS => 't/*.t t/*/*.t' },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'xDT-Parser-*' },
);
