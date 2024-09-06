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
    NAME                => 'WebSocket',
    VERSION_FROM        => 'lib/WebSocket.pm',
    AUTHOR              => 'Jacques Deguest (jack@deguest.jp)',
    ABSTRACT_FROM       => 'lib/WebSocket.pm',
    INSTALLDIRS         => ($] < 5.011 ? 'perl' : 'site'),
    PREREQ_PM           => {
        'constant'          => 0,
        'overload'          => 0,
        'parent'            => 0,
        'strict'            => '0.238',
        'vars'              => 0,
        'warnings'          => '1.44',
        'Config'            => 0,
        'Digest::MD5'       => '2.58',
        'Digest::SHA'       => '6.02',
        'Encode'            => '3.08',
        'HTTP::Headers'     => '6.22',
        'HTTP::Request'     => '6.22',
        'HTTP::Response'    => '6.22',
        'HTTP::Status'      => '6.22',
        'IO::Select'        => '1.41',
        'IO::Socket'        => '1.42',
        'IO::Socket::INET'  => '1.41',
        'JSON'              => '4.03',
        'List::Util'        => '1.56',
        'MIME::Base64'      => '3.16',
        'Module::Generic'   => 'v0.37.5',
        'Nice::Try'         => 'v1.3.13',
        'POSIX'             => '1.53_01',
        # Just to ensure URI::_generic does not die when requiring it
        'Regexp::IPv6'      => 0,
        'Scalar::Util'      => '1.56',
        'Socket'            => '2.031',
        'URI'               => '5.21',
        'URI::ws'           => '0.03',
        'Want'              => '0.29',
    },
    TEST_REQUIRES =>
    {
        'utf8'          => 0,
        'version'       => 0,
        'Test::More'    => '1.302182',
        'Test::Pod'     => '1.52',
        'Test2::IPC'    => '1.302190',
        'Test2::V0'     => '0.000145',
    },
    EXE_FILES           => [],
    LICENSE             => 'perl_5',
    MIN_PERL_VERSION    => 'v5.14.0',
    (MM->can('signature_target') ? (SIGN => 1) : ()),
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', DIST_CP => 'cp' },
    clean               => { FILES => 'WebSocket-*' },
    ( eval { ExtUtils::MakeMaker->VERSION(6.46) } ? ( META_MERGE => {
        'meta-spec' => { version => 2 },
        dynamic_config => 1,
        resources => {
        #    homepage    => undef,
            repository  => {
                url         => 'git@gitlab.com:jackdeguest/WebSocket.git',
                web         => 'https://gitlab.com/jackdeguest/WebSocket',
                type        => 'git',
            },
            bugtracker => {
                web         => 'https://gitlab.com/jackdeguest/WebSocket/issues',
            },
        },
    }) : ()),
);

WriteMakefile(%WriteMakefileArgs);
