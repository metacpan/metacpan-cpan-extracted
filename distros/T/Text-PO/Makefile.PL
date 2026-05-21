use ExtUtils::MakeMaker;
use strict;
use warnings;

sub MY::distsignature
{
    return << 'EOT';
distsignature : distmeta
	$(NOECHO) ./dev/cleanup.pl
	$(NOECHO) cd $(DISTVNAME) && $(ABSPERLRUN) -MExtUtils::Manifest=maniadd -e 'eval { maniadd({q{SIGNATURE} => q{Public-key signature (added by MakeMaker)}}) }' \
	  -e '	  or die "Could not add SIGNATURE to MANIFEST: $${'\''@'\''}"' --
	$(NOECHO) cd $(DISTVNAME) && $(TOUCH) SIGNATURE
	cd $(DISTVNAME) && cpansign -s
EOT
}

my %WriteMakefileArgs = (
    NAME                => 'Text::PO',
    VERSION_FROM        => 'lib/Text/PO.pm',
    AUTHOR              => 'Jacques Deguest (jack@deguest.jp)',
    ABSTRACT_FROM       => 'lib/Text/PO.pm',
    INSTALLDIRS         => ($] < 5.011 ? 'perl' : 'site'),
    PREREQ_PM           => {
        'open'                  => '1.11',
        'overload'              => '1.30',
        'parent'                => 0,
        'strict'                => '0.238',
        'vars'                  => 0,
        'warnings'              => 0,
        'Class::Struct'         => '0.65',
        'DateTime::Format::Lite' => 'v0.1.3',
        'DateTime::Lite'        => 'v0.6.5',
        # Based on 2011-05-15 (perl v5.14.0) availability
        # https://metacpan.org/release/DANKOGAI/Encode-2.42/source/Encode.pm
        'Encode'                => '2.42',
        # Based on perl v5.14.0
        # https://metacpan.org/release/JESSE/perl-5.14.0/view/ext/Fcntl/Fcntl.pm
        'Fcntl'                 => '1.11',
        # Based on the perl v5.14.0
        # https://metacpan.org/release/JESSE/perl-5.14.0/source/ext/I18N-Langinfo/Langinfo.pm
        'I18N::Langinfo'        => '0.08',
        'IO::File'              => 0,
        'JSON'                  => '2.97001',
        'JSON::XS'              => '4.03',
        'Module::Generic'       => 'v1.3.0',
        'POSIX'                 => '1.53_01',
        'Scalar::Util'          => '1.50',
        'Text::Wrap'            => '2013.0523',
    },
    TEST_REQUIRES =>
    {
        'utf8'          => 0,
        'File::Spec'    => 0,
        'POSIX'         => '1.53_01',
        'Test::More'    => '1.302133',
        'Test::Pod'     => '1.50',
    },
    EXE_FILES           => [qw(
        scripts/po.pl
    )],
    LICENSE             => 'perl_5',
    # 2011-05-14
    MIN_PERL_VERSION    => 'v5.28.0',
    (MM->can('signature_target') ? (SIGN => 1) : ()),
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', DIST_CP => 'cp' },
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
