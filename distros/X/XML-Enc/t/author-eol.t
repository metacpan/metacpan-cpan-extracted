
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
    'lib/XML/Enc.pm',
    't/00-basic.t',
    't/01-decrypt.t',
    't/02-decrypt-saml.t',
    't/03-encrypt.t',
    't/04-decrypt.t',
    't/05-invalid-xml.t',
    't/06-test-encryption-methods.t',
    't/07-decrypt-xmlsec.t',
    't/author-critic.t',
    't/author-eof.t',
    't/author-eol.t',
    't/author-no-tabs.t',
    't/author-pod-coverage.t',
    't/author-pod-syntax.t',
    't/release-trailing-space.t',
    't/sign-certonly.pem',
    't/sign-private.pem'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
