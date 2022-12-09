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
        'vars'          => 0,
        'warnings'      => '1.44',
        'Class::Struct' => '0.65',
        'DateTime'      => '1.58',
        'DateTime::TimeZone' => '2.52',
        'Encode'        => '3.08',
        'Fcntl'         => '1.13',
        'I18N::Langinfo'=> '0.19',
        'IO::File'      => '1.41',
        'JSON'          => '4.07',
        'JSON::XS'      => '4.03',
        'Module::Generic'=> 'v0.29.1',
        'Nice::Try'     => 'v1.3.1',
        'POSIX'         => '1.53_01',
        'Scalar::Util'  => '1.50',
        'Text::Wrap'    => '2021.0814',
    },
    TEST_REQUIRES =>
    {
        'utf8'          => 0,
        'File::Spec'    => '3.78',
        'POSIX'         => '1.53_01',
        'Test::More'    => '1.302182',
        'Test::Pod'     => '1.52',
    },
    EXE_FILES           => [qw(
        scripts/po.pl
    )],
    LICENSE             => 'perl_5',
    MIN_PERL_VERSION    => 'v5.14.0',
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', PREOP => './dev/cleanup.pl' },
    clean               => { FILES => 'Text-PO-*' },
    ( eval { ExtUtils::MakeMaker->VERSION(6.46) } ? ( META_MERGE => {
        'meta-spec' => { version => 2 },
        dynamic_config => 1,
        resources => {
        #    homepage    => undef,
            repository  => {
                url         => 'git@gitlab.com:jackdeguest/Text-PO.git',
                web         => 'https://gitlab.com/jackdeguest/Text-PO',
                type        => 'git',
            },
            bugtracker => {
                web         => 'https://gitlab.com/jackdeguest/Text-PO/issues',
            },
        },
    }) : ()),
);

WriteMakefile(%WriteMakefileArgs);
