
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
    'lib/WebService/Mocean.pm',
    'lib/WebService/Mocean/Account.pm',
    'lib/WebService/Mocean/Client.pm',
    'lib/WebService/Mocean/Report.pm',
    'lib/WebService/Mocean/Sms.pm',
    't/00-compile.t',
    't/000-report-versions.t',
    't/00_compile.t',
    't/01_instantiation.t',
    't/02_request.t',
    't/03_auth_params.t',
    't/04_check_required_params.t',
    't/05_sms_send.t',
    't/06_sms_send_verification_code.t',
    't/07_sms_check_verification_code.t',
    't/08_account_get_balance.t',
    't/09_account_get_pricing.t',
    't/10_report_get_message_status.t',
    't/author-eol.t',
    't/author-minimum-version.t',
    't/author-pod-coverage.t',
    't/author-pod-syntax.t',
    't/release-distmeta.t',
    't/release-has-version.t',
    't/release-kwalitee.t',
    't/release-unused-vars.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
