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
    NAME                => 'Web::Authn',
    AUTHOR              => 'Jacques Deguest (jack@deguest.jp)',
    VERSION_FROM        => 'lib/Web/Authn.pm',
    ABSTRACT_FROM       => 'lib/Web/Authn.pm',
    PL_FILES            => {},
    PREREQ_PM           => {
        'parent'                => 0,
        'strict'                => 0,
        'warnings'              => 0,
        'Bytes::Random::Secure' => '0.29',
        'CryptX'                => '0.074',
        'Digest::SHA'           => 0,
        'Exporter'              => 0,
        # On Perl 5.14+, JSON::PP is in core. We still auto-detect faster backends
        # (Cpanel::JSON::XS, JSON::XS) at runtime in DateTime::Lite::TimeZone, but neither
        # is required.
        # 'JSON'                  => 0,
        'MIME::Base64'          => 0,
        # Version compatible with perl v5.10
        'Wanted'                => 'v0.1.2',
    },
    TEST_REQUIRES =>
    {
        'lib'               => 0,
        'Test::More'        => '0.98',
        'Test::Pod'         => '1.52',
    },
    LICENSE             => 'perl_5',
    MIN_PERL_VERSION    => 'v5.16.0',
    (MM->can('signature_target') ? (SIGN => 1) : ()),
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', DIST_CP => 'cp', PREOP => './dev/cleanup.pl' },
    clean               => { FILES => 'Web-Authn-*' },
    ( eval { ExtUtils::MakeMaker->VERSION(6.46) } ? ( META_MERGE => {
        'meta-spec' => { version => 2 },
        dynamic_config => 1,
        resources => {
            # homepage    => undef,
            repository  => {
                url         => 'git@gitlab.com:deguest/Web-Authn.git',
                web         => 'https://gitlab.com/deguest/Web-Authn',
                type        => 'git',
            },
            bugtracker => {
                web         => 'https://gitlab.com/deguest/Web-Authn/issues',
            },
        },
    }) : ()),
);

WriteMakefile(%WriteMakefileArgs);

