use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/WWW/YouTube/Download.pm',
    'script/youtube-download',
    'script/youtube-playlists',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/00_compile.t',
    't/data/player_response.html',
    't/player_response.t',
    't/playlist_id.t',
    't/user_id.t',
    't/video_id.t',
    't/video_user.t',
    't/youtube.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
