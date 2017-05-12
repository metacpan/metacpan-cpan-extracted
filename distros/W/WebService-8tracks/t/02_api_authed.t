use strict;
use warnings;
no  warnings qw(once redefine);
use Test::More tests => 9;
use Test::Deep qw(cmp_deeply isa methods superhashof noclass bool ignore);

use Data::Section::Simple qw(get_data_section);
use LWP::UserAgent;
use HTTP::Response;

use WebService::8tracks;

my %request_seen;

*LWP::UserAgent::request = sub {
    my ($self, $req) = @_;

    my $key = $req->method . ' ' . $req->uri;
    if ($request_seen{$key}++) {
        $key = "$key ($request_seen{$key})";
    }

    my $data = get_data_section($key) or die "response not found: $key";
    return HTTP::Response->parse($data);
};

# Responses are recorded in DATA, so no real auth info is required
my $api = new_ok 'WebService::8tracks', [ username => 'motemen', password => '...' ];

my $fav_res = $api->fav(109569);
cmp_deeply $fav_res,
    isa('WebService::8tracks::Response')
        & methods(is_success => bool(1))
        & noclass(superhashof {
            logged_in => bool(1),
            track => superhashof { name => 'Rinbu - Revolution', faved_by_current_user => bool(1) },
        }),
    '$api->fav';

my $unfav_res = $api->unfav(109569);
cmp_deeply $unfav_res,
    isa('WebService::8tracks::Response')
        & methods(is_success => bool(1))
        & noclass(superhashof {
            logged_in => bool(1),
            track => superhashof { name => 'Rinbu - Revolution', faved_by_current_user => bool(0) },
        }),
    '$api->unfav';

my $toggle_fav_res = $api->toggle_fav(109569);
cmp_deeply $toggle_fav_res,
    isa('WebService::8tracks::Response')
        & methods(is_success => bool(1))
        & noclass(superhashof {
            logged_in => bool(1),
            track => superhashof { name => 'Rinbu - Revolution', faved_by_current_user => bool(1) },
        }),
    '$api->toggle_fav';

my $toggle_follow_res = $api->toggle_follow('youpy');
cmp_deeply $toggle_follow_res,
    isa('WebService::8tracks::Response')
        & methods(is_success => bool(1))
        & noclass(superhashof {
            logged_in => bool(1),
            user => superhashof { slug => 'youpy', followed_by_current_user => bool(0) }, # I've been following before
        }),
    '$api->toggle_follow';

my $follow_res = $api->follow('youpy');
cmp_deeply $follow_res,
    isa('WebService::8tracks::Response')
        & methods(is_success => bool(1))
        & noclass(superhashof {
            logged_in => bool(1),
            user => superhashof { slug => 'youpy', followed_by_current_user => bool(1) },
        }),
    '$api->toggle_follow';

my $follow_self_res = $api->follow('motemen');
cmp_deeply $follow_self_res,
    isa('WebService::8tracks::Response')
        & methods(is_success => bool(0))
        & noclass(superhashof {
            status => '422 Unprocessable Entity',
            errors => ['There was a problem'],
        }),
    '$api->follow (self)';

my $follow_nosuchuser_res = $api->follow('no_such_user');
cmp_deeply $follow_nosuchuser_res,
    isa('WebService::8tracks::Response')
        & methods(is_success => bool(0))
        & noclass(superhashof {
            status => '404 Not Found',
        }),
    '$api->follow (no_such_user)';

my $like_res = $api->like(7063);
cmp_deeply $like_res,
    isa('WebService::8tracks::Response')
        & methods(is_success => bool(1))
        & noclass(superhashof {
            logged_in => bool(1),
            mix => superhashof {
                slug => 'g8',
                user => superhashof { slug => 'youpy' },
            },
        }),
    '$api->like';

__DATA__

@@ POST http://api.8tracks.com/tracks/109569/fav.json
HTTP/1.1 200 OK
Content-Length: 277
Content-Type: application/json; charset=utf-8

{"notices":null,"logged_in":true,"status":"200 OK","track":{"name":"Rinbu - Revolution","faved_by_current_user":true,"url":"http://8tracks.com/tracks/109569","release_name":"Star Mania: Shoujo Kakumei Utena","performer":"Okui Masami","id":109569,"user_id":12812},"errors":null}

@@ POST http://api.8tracks.com/tracks/109569/unfav.json
HTTP/1.1 200 OK
Content-Length: 278
Content-Type: application/json; charset=utf-8

{"notices":null,"logged_in":true,"status":"200 OK","track":{"name":"Rinbu - Revolution","faved_by_current_user":false,"url":"http://8tracks.com/tracks/109569","release_name":"Star Mania: Shoujo Kakumei Utena","performer":"Okui Masami","id":109569,"user_id":12812},"errors":null}

@@ POST http://api.8tracks.com/tracks/109569/toggle_fav.json
HTTP/1.1 200 OK
Content-Length: 277
Content-Type: application/json; charset=utf-8

{"notices":null,"logged_in":true,"status":"200 OK","track":{"name":"Rinbu - Revolution","faved_by_current_user":true,"url":"http://8tracks.com/tracks/109569","release_name":"Star Mania: Shoujo Kakumei Utena","performer":"Okui Masami","id":109569,"user_id":12812},"errors":null}

@@ POST http://api.8tracks.com/users/youpy/toggle_follow.json
HTTP/1.1 200 OK
Content-Length: 507
Content-Type: application/json; charset=utf-8

{"notices":null,"logged_in":true,"status":"200 OK","errors":null,"user":{"slug":"youpy","location":"","bio_html":null,"next_mix_prefs":"ask","id":7535,"avatar_urls":{"max200":"http://cf3.8tracks.us/avatars/000/007/535/36384.max200.jpg","sq56":"http://cf3.8tracks.us/avatars/000/007/535/36384.sq56.jpg","sq72":"http://cf3.8tracks.us/avatars/000/007/535/36384.sq72.jpg","sq100":"http://cf3.8tracks.us/avatars/000/007/535/36384.sq100.jpg"},"popup_prefs":"ask","followed_by_current_user":false,"login":"youpy"}}

@@ POST http://api.8tracks.com/users/youpy/follow.json
HTTP/1.1 200 OK
Content-Length: 506
Content-Type: application/json; charset=utf-8

{"notices":null,"logged_in":true,"status":"200 OK","errors":null,"user":{"slug":"youpy","location":"","bio_html":null,"next_mix_prefs":"ask","id":7535,"avatar_urls":{"max200":"http://cf3.8tracks.us/avatars/000/007/535/36384.max200.jpg","sq56":"http://cf3.8tracks.us/avatars/000/007/535/36384.sq56.jpg","sq72":"http://cf3.8tracks.us/avatars/000/007/535/36384.sq72.jpg","sq100":"http://cf3.8tracks.us/avatars/000/007/535/36384.sq100.jpg"},"popup_prefs":"ask","followed_by_current_user":true,"login":"youpy"}}

@@ POST http://api.8tracks.com/users/motemen/follow.json
HTTP/1.1 422 Unprocessable Entity
Content-Length: 102
Content-Type: application/json; charset=utf-8

{"notices":null,"logged_in":true,"status":"422 Unprocessable Entity","errors":["There was a problem"]}

@@ POST http://api.8tracks.com/users/no_such_user/follow.json
HTTP/1.1 404 Not Found
Content-Length: 72
Content-Type: application/json; charset=utf-8

{"notices":null,"logged_in":true,"status":"404 Not Found","errors":null}

@@ POST http://api.8tracks.com/mixes/7063/like.json
HTTP/1.1 200 OK
Content-Length: 1315
Content-Type: application/json; charset=utf-8

{"notices":null,"logged_in":true,"status":"200 OK","errors":null,"mix":{"path":"/youpy/g8","slug":"g8","name":"G8","user":{"slug":"youpy","id":7535,"avatar_urls":{"max200":"http://cf3.8tracks.us/avatars/000/007/535/36384.max200.jpg","sq56":"http://cf3.8tracks.us/avatars/000/007/535/36384.sq56.jpg","sq72":"http://cf3.8tracks.us/avatars/000/007/535/36384.sq72.jpg","sq100":"http://cf3.8tracks.us/avatars/000/007/535/36384.sq100.jpg"},"followed_by_current_user":true,"login":"youpy"},"published":true,"cover_urls":{"max200":"http://cf3.8tracks.us/mix_covers/000/007/063/99858.max200.jpg","max133w":"http://cf3.8tracks.us/mix_covers/000/007/063/99858.max133w.jpg","original":"http://cf3.8tracks.us/mix_covers/000/007/063/99858.original.jpg","sq56":"http://cf3.8tracks.us/mix_covers/000/007/063/99858.sq56.jpg","sq133":"http://cf3.8tracks.us/mix_covers/000/007/063/99858.sq133.jpg","sq100":"http://cf3.8tracks.us/mix_covers/000/007/063/99858.sq100.jpg"},"id":7063,"liked_by_current_user":true,"tag_list_cache":"alternative rock, eclectic","plays_count":31,"description":"Eight tracks of alternative & punk, alternative rock and unclassifiable, including music by Bruce Russell, Greg Malcolm & Tetuzi Akiyama, and Kevin Drumm.","restful_url":"http://8tracks.com/mixes/7063","first_published_at":"2008-11-21T06:08:56Z"}}

