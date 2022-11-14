use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'bin/mock_onfido.pl',
    'bin/onfido-tool',
    'lib/WebService/Async/Onfido.pm',
    'lib/WebService/Async/Onfido.pod',
    'lib/WebService/Async/Onfido/Address.pm',
    'lib/WebService/Async/Onfido/Address.pod',
    'lib/WebService/Async/Onfido/Applicant.pm',
    'lib/WebService/Async/Onfido/Applicant.pod',
    'lib/WebService/Async/Onfido/Base/Address.pm',
    'lib/WebService/Async/Onfido/Base/Applicant.pm',
    'lib/WebService/Async/Onfido/Base/Check.pm',
    'lib/WebService/Async/Onfido/Base/Document.pm',
    'lib/WebService/Async/Onfido/Base/Photo.pm',
    'lib/WebService/Async/Onfido/Base/Report.pm',
    'lib/WebService/Async/Onfido/Base/Video.pm',
    'lib/WebService/Async/Onfido/Check.pm',
    'lib/WebService/Async/Onfido/Check.pod',
    'lib/WebService/Async/Onfido/Document.pm',
    'lib/WebService/Async/Onfido/Document.pod',
    'lib/WebService/Async/Onfido/Photo.pm',
    'lib/WebService/Async/Onfido/Photo.pod',
    'lib/WebService/Async/Onfido/Report.pm',
    'lib/WebService/Async/Onfido/Report.pod',
    'lib/WebService/Async/Onfido/Video.pm',
    'lib/WebService/Async/Onfido/Video.pod',
    't/00-check-deps.t',
    't/00-compile.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/onfido.t',
    't/rc/perlcriticrc',
    't/rc/perltidyrc',
    't/supported_documents.t',
    'xt/author/critic.t',
    'xt/author/distmeta.t',
    'xt/author/eol.t',
    'xt/author/minimum-version.t',
    'xt/author/mojibake.t',
    'xt/author/no-tabs.t',
    'xt/author/pod-syntax.t',
    'xt/author/portability.t',
    'xt/author/test-version.t',
    'xt/release/common_spelling.t',
    'xt/release/cpan-changes.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
