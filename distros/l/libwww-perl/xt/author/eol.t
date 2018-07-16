use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'bin/lwp-download',
    'bin/lwp-dump',
    'bin/lwp-mirror',
    'bin/lwp-request',
    'lib/LWP.pm',
    'lib/LWP/Authen/Basic.pm',
    'lib/LWP/Authen/Digest.pm',
    'lib/LWP/Authen/Ntlm.pm',
    'lib/LWP/ConnCache.pm',
    'lib/LWP/Debug.pm',
    'lib/LWP/Debug/TraceHTTP.pm',
    'lib/LWP/DebugFile.pm',
    'lib/LWP/MemberMixin.pm',
    'lib/LWP/Protocol.pm',
    'lib/LWP/Protocol/cpan.pm',
    'lib/LWP/Protocol/data.pm',
    'lib/LWP/Protocol/file.pm',
    'lib/LWP/Protocol/ftp.pm',
    'lib/LWP/Protocol/gopher.pm',
    'lib/LWP/Protocol/http.pm',
    'lib/LWP/Protocol/loopback.pm',
    'lib/LWP/Protocol/mailto.pm',
    'lib/LWP/Protocol/nntp.pm',
    'lib/LWP/Protocol/nogo.pm',
    'lib/LWP/RobotUA.pm',
    'lib/LWP/Simple.pm',
    'lib/LWP/UserAgent.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/10-attrs.t',
    't/base/default_content_type.t',
    't/base/protocols.t',
    't/base/protocols/nntp.t',
    't/base/proxy.t',
    't/base/simple.t',
    't/base/ua.t',
    't/base/ua_handlers.t',
    't/leak/no_leak.t',
    't/local/autoload-get.t',
    't/local/autoload.t',
    't/local/get.t',
    't/local/http.t',
    't/local/httpsub.t',
    't/local/protosub.t',
    't/robot/ua-get.t',
    't/robot/ua.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
