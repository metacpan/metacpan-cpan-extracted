use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'bin/vs-download.pl',
    'bin/vs-upload.pl',
    'lib/WebService/ValidSign.pm',
    'lib/WebService/ValidSign/API.pm',
    'lib/WebService/ValidSign/API/Account.pm',
    'lib/WebService/ValidSign/API/Auth.pm',
    'lib/WebService/ValidSign/API/Constructor.pm',
    'lib/WebService/ValidSign/API/DocumentPackage.pm',
    'lib/WebService/ValidSign/Object.pm',
    'lib/WebService/ValidSign/Object/Auth.pm',
    'lib/WebService/ValidSign/Object/Ceremony.pm',
    'lib/WebService/ValidSign/Object/Document.pm',
    'lib/WebService/ValidSign/Object/DocumentPackage.pm',
    'lib/WebService/ValidSign/Object/Sender.pm',
    'lib/WebService/ValidSign/Object/Signature.pm',
    'lib/WebService/ValidSign/Object/Signer.pm',
    'lib/WebService/ValidSign/Types.pm',
    't/00-compile.t',
    't/01-basic.t',
    't/02-types.t',
    't/100-auth.t',
    't/110-account.t',
    't/200-document-package.t',
    't/210-document-package-api.t',
    't/lib/Test/WebService/ValidSign.pm'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
