
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

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
    't/011-sign_multiple_sections.t',
    't/012_unassociated_signatures.t',
    't/013_inclusive_prefixes.t',
    't/014_verify_issues.t',
    't/author-critic.t',
    't/author-eof.t',
    't/author-eol.t',
    't/author-no-tabs.t',
    't/author-pod-coverage.t',
    't/author-pod-syntax.t',
    't/cacert.pem',
    't/dsa.private.key',
    't/intermediate.pem',
    't/issues/issue-20.xml',
    't/pkcs8.private.key',
    't/release-trailing-space.t',
    't/rsa.cert.pem',
    't/rsa.private.key',
    't/signed/inclusive.xml',
    't/signed/logout_response.xml',
    't/signed/one-of-three-sigs-unassocated.xml',
    't/signed/saml_request-xmlsec1-dsa-signed.xml',
    't/signed/saml_request-xmlsec1-rsa-signed.xml',
    't/signed/saml_response.xml',
    't/signed/unassociated-signature-issue.xml',
    't/signed/xmlsec1-signed-dsa-multiple.xml',
    't/signed/xmlsec1-signed-rsa-multiple.xml',
    't/sso.cert.pem',
    't/unsigned/saml_request.xml',
    't/unsigned/sign_multiple_sections.xml',
    't/unsigned/xml-sig-unsigned-dsa-multiple.xml',
    't/unsigned/xml-sig-unsigned-rsa-multiple.xml',
    't/xmlsec1_commands_to_sign_verify.txt'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
