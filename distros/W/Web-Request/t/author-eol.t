
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
    'lib/Web/Request.pm',
    'lib/Web/Request/Types.pm',
    'lib/Web/Request/Upload.pm',
    'lib/Web/Response.pm',
    't/00-compile.t',
    't/author-eol.t',
    't/author-no-tabs.t',
    't/author-pod-coverage.t',
    't/author-pod-syntax.t',
    't/base.t',
    't/body.t',
    't/content-on-get.t',
    't/content.t',
    't/cookie.t',
    't/data/foo1.txt',
    't/data/foo2.txt',
    't/double_port.t',
    't/encoding.t',
    't/hostname.t',
    't/many_upload.t',
    't/multi_read.t',
    't/new.t',
    't/parameters.t',
    't/params.t',
    't/path_info.t',
    't/path_info_escaped.t',
    't/readbody.t',
    't/request_uri.t',
    't/response-body.t',
    't/response-compatible.t',
    't/response-cookie.t',
    't/response-new.t',
    't/response-redirect.t',
    't/response-streaming-cookie.t',
    't/response-streaming-utf8.t',
    't/response-streaming.t',
    't/response-to_app.t',
    't/response.t',
    't/upload-basename.t',
    't/upload-large.t',
    't/upload.t',
    't/uri.t',
    't/uri_utf8.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
