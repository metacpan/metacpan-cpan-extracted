use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME => 'VPNDetection',
    VERSION_FROM => 'lib/VPNDetection.pm',
    ABSTRACT => 'Official Perl client library for the VPNDetection API',
    AUTHOR => 'Mslm Dev <support@vpndetection.io>',
    LICENSE => 'mit',
    MIN_PERL_VERSION => '5.022',
    PREREQ_PM => {
        # The whole HTTP stack, the JSON codec, the event loop and the promises,
        # from one distribution with no non-core dependencies of its own. Every body
        # is decoded by Mojo::JSON, which a deeply nested one could exhaust before
        # 9.47 (CVE-2026-14803).
        'Mojolicious' => '9.47',
        # Mojolicious makes TLS optional; the API is HTTPS only, so we do not.
        'IO::Socket::SSL' => '2.009',
    },
    # Safe to declare rather than fold into PREREQ_PM: TEST_REQUIRES needs
    # ExtUtils::MakeMaker 6.64, and perl 5.022000 already shipped 7.04_01.
    TEST_REQUIRES => {
        'Test::More' => '0.98',
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        keywords => [qw(
            vpn vpn-detection proxy-detection tor ip-intelligence
            fraud-prevention residential-proxy hosting cdn relay
        )],
        resources => {
            homepage => 'https://vpndetection.io',
            repository => {
                type => 'git',
                url => 'https://github.com/vpndetection-io/sdk-perl.git',
                web => 'https://github.com/vpndetection-io/sdk-perl',
            },
            bugtracker => {
                web => 'https://github.com/vpndetection-io/sdk-perl/issues',
            },
        },
        no_index => {
            directory => ['t'],
        },
    },
    # t/*.t only: integration/t installs this distribution from CPAN and tests
    # that, so it is neither shipped nor run from here.
    test => { TESTS => 't/*.t' },
    clean => { FILES => 'VPNDetection-*' },
);
