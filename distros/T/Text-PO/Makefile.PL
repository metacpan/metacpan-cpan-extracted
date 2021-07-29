use ExtUtils::MakeMaker;
use strict;
use warnings;

# Call 'perldoc ExtUtils::MakeMaker' for details of how to influence
# the contents of the Makefile that is written.

my %WriteMakefileArgs = (
    NAME                => 'Text::PO',
    VERSION_FROM        => 'lib/Text/PO.pm',
    AUTHOR              => 'Jacques Deguest (jack@deguest.jp)',
    ABSTRACT_FROM       => 'lib/Text/PO.pm',
    INSTALLDIRS         => ($] < 5.011 ? 'perl' : 'site'),
    PREREQ_PM           => {
        'open'          => '1.11',
        'overload'      => '1.30',
        'parent'        => 0,
        'strict'        => '0.238',
        'warnings'      => '1.44',
        'Class::Struct' => '0.65',
        'DateTime'      => '1.54',
        'Encode'        => '3.08',
        'Fcntl'         => '1.13',
        'IO::File'      => '1.41',
        'JSON'          => '4.03',
        'Module::Generic'=> 'v0.15.4',
        'Nice::Try'     => 'v1.1.2',
        'Scalar::Util'  => '1.50',
        'Text::Wrap'    => '2013.0523',
    },
    TEST_REQUIRES =>
    {
        'utf8'          => 0,
        'File::Spec'    => '3.78',
        'Test::More'    => '1.302182',
        'Test::Pod'     => '1.52',
    },
    EXE_FILES           => [qw(
        scripts/po.pl
    )],
    LICENSE             => 'perl_5',
    MIN_PERL_VERSION    => 'v5.14.0',
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Text-PO-*' },
    ( eval { ExtUtils::MakeMaker->VERSION(6.46) } ? ( META_MERGE => {
        'meta-spec' => { version => 2 },
        dynamic_config => 1,
        resources => {
        #    homepage    => undef,
            repository  => {
                url         => 'git@git.deguest.jp:jack/Text-PO.git',
                web         => 'https://git.deguest.jp/jack/Text-PO',
                type        => 'git',
            },
            bugtracker => {
                web         => 'https://git.deguest.jp/jack/Text-PO/issues',
            },
        },
    }) : ()),
);

WriteMakefile(%WriteMakefileArgs);
