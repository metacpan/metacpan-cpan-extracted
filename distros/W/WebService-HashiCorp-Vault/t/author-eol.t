
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
    'lib/WebService/HashiCorp/Vault.pm',
    'lib/WebService/HashiCorp/Vault/Base.pm',
    'lib/WebService/HashiCorp/Vault/Secret/Cassandra.pm',
    'lib/WebService/HashiCorp/Vault/Secret/Cubbyhole.pm',
    'lib/WebService/HashiCorp/Vault/Secret/Generic.pm',
    'lib/WebService/HashiCorp/Vault/Secret/LeasableBase.pm',
    'lib/WebService/HashiCorp/Vault/Secret/MSSQL.pm',
    'lib/WebService/HashiCorp/Vault/Secret/MongoDB.pm',
    'lib/WebService/HashiCorp/Vault/Secret/MySQL.pm',
    'lib/WebService/HashiCorp/Vault/Secret/PostgreSQL.pm',
    'lib/WebService/HashiCorp/Vault/Secret/RabbitMQ.pm',
    'lib/WebService/HashiCorp/Vault/Secret/SSH.pm',
    'lib/WebService/HashiCorp/Vault/Sys.pm',
    't/00-compile.t',
    't/000-load.t',
    't/001-vault.t',
    't/author-critic.t',
    't/author-eof.t',
    't/author-eol.t',
    't/author-no-breakpoints.t',
    't/author-no-tabs.t',
    't/author-pod-coverage.t',
    't/author-pod-syntax.t',
    't/author-portability.t',
    't/release-distmeta.t',
    't/release-kwalitee.t',
    't/release-unused-vars.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
