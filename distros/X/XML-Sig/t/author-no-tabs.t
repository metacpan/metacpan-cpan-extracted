
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/XML/Sig.pm',
    't/001_load.t',
    't/002_xmlsec.t',
    't/003_params.t',
    't/004_keyhandling.t',
    't/005_rsakeys.t',
    't/006_signing.t',
    't/007_verify_saml.t',
    't/008_sign_saml.t',
    't/009_verify_separate_cert.t',
    't/author-critic.t',
    't/author-eof.t',
    't/author-eol.t',
    't/author-no-tabs.t',
    't/author-pod-coverage.t',
    't/author-pod-syntax.t',
    't/cacert.pem',
    't/dsa.private.key',
    't/intermediate.pem',
    't/logout_response.xml',
    't/pkcs8.private.key',
    't/release-trailing-space.t',
    't/rsa.cert.pem',
    't/rsa.private.key',
    't/saml_request.xml',
    't/saml_response.xml',
    't/sso.cert.pem'
);

notabs_ok($_) foreach @files;
done_testing;
