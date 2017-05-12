use strict;
use warnings;
no  warnings qw(once redefine);
use Test::More tests => 15;
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

my $api = new_ok 'WebService::8tracks';

my $user = $api->user(1);
cmp_deeply $user,
    isa('WebService::8tracks::Response')
        & methods(is_success => 1)
        & noclass(superhashof { user => superhashof { slug => 'remi' } }),
    '$api->user';

my $mixes = $api->user_mixes('dp');
cmp_deeply $mixes,
    isa('WebService::8tracks::Response')
        & methods(is_success => 1)
        & noclass(superhashof {
            next_page     => 2,
            total_entries => 41,
            mixes         => isa('ARRAY'),
        }),
    '$api->user_mixes';

my $mix = $mixes->{mixes}->[0];
cmp_deeply $mix,
    superhashof({
        id   => 163823,
        slug => 'a-new-mission',
        name => 'A new mission',
        path => '/dp/a-new-mission',
        user => superhashof { slug => 'dp' },
        tag_list_cache => 'electronic, chillwave, minimal',
    }),
    '$mixes->{mixes}->[0]';

my $session = $api->create_session(163823);
isa_ok $session, 'WebService::8tracks::Session';

sub like_a_track_response {
    my %config = @_;

    return isa('WebService::8tracks::Response')
        & methods(is_success => 1)
        & noclass(superhashof {
            set => superhashof {
                at_beginning => bool(0),
                at_end       => bool(0),
                track        => superhashof({
                    url          => ignore,
                    name         => ignore,
                    performer    => ignore,
                    release_name => ignore,
                }),
                %config,
            }
        });
}

cmp_deeply $session->play,
    like_a_track_response(
        at_beginning => bool(1),
        track        => superhashof({
            url          => ignore,
            name         => 'You',
            performer    => 'Gold Panda',
            release_name => 'Lucky Shiner',
        }),
    ),
    '$session->play';

cmp_deeply $session->next,
    like_a_track_response(),
    '$session->next';

cmp_deeply $session->skip,
    like_a_track_response(skip_allowed => bool(1)),
    '$session->skip';

cmp_deeply $session->skip,
    like_a_track_response(skip_allowed => bool(0)),
    '$session->skip (2)';

cmp_deeply $session->skip,
    methods(is_success => bool(0), is_client_error => bool(1)) & noclass(superhashof { status => '403 Forbidden' }),
    '$session->skip (3, not allowed)';

cmp_deeply $session->next,
    like_a_track_response(),
    '$session->next (2)';

cmp_deeply $session->next,
    like_a_track_response(),
    '$session->next (3)';

cmp_deeply $session->next,
    like_a_track_response(),
    '$session->next (4)';

cmp_deeply $session->next,
    like_a_track_response(),
    '$session->next (5)';

cmp_deeply $session->next,
    like_a_track_response(at_end => bool(1), track => {}),
    '$session->next (6, end)';

__DATA__

@@ GET http://api.8tracks.com/users/1.json
HTTP/1.1 200 OK
Content-Length: 788
Content-Type: application/json; charset=utf-8

{"notices":null,"user":{"slug":"remi","followed_by_current_user":false,"location":"Noe Valley, San Francisco, US","bio_html":"<p>Frenchman. I co-founded 8tracks with my very first boss from 7 years ago, <a href=\"/dp\">dp</a>.</p>\n\n<p>When I have time, I spend it hacking Ruby on Rails code to make 8tracks better. I'm on the photo of the 8tracks <a href=\"/store\">t-shirt</a>.</p>","next_mix_prefs":"ask","id":1,"popup_prefs":"ask","login":"remi","avatar_urls":{"sq100":"http://cf1.8tracks.us/avatars/000/000/001/12363.sq100.jpg","max200":"http://cf1.8tracks.us/avatars/000/000/001/12363.max200.jpg","sq56":"http://cf1.8tracks.us/avatars/000/000/001/12363.sq56.jpg","sq72":"http://cf1.8tracks.us/avatars/000/000/001/12363.sq72.jpg"}},"status":"200 OK","logged_in":false,"errors":null}

@@ GET http://api.8tracks.com/users/dp/mixes.json
HTTP/1.1 200 OK
Content-Length: 13401
Content-Type: application/json; charset=utf-8

{"offset":null,"notices":null,"next_page":2,"status":"200 OK","total_entries":41,"logged_in":false,"page":1,"errors":null,"per_page":10,"mix_set_id":123,"mixes":[{"path":"/dp/a-new-mission","slug":"a-new-mission","name":"A new mission","user":{"slug":"dp","followed_by_current_user":false,"id":2,"login":"dp","avatar_urls":{"sq100":"http://cf2.8tracks.us/avatars/000/000/002/24734.sq100.jpg","max200":"http://cf2.8tracks.us/avatars/000/000/002/24734.max200.jpg","sq56":"http://cf2.8tracks.us/avatars/000/000/002/24734.sq56.jpg","sq72":"http://cf2.8tracks.us/avatars/000/000/002/24734.sq72.jpg"}},"restful_url":"http://8tracks.com/mixes/163823","published":true,"cover_urls":{"max133w":"http://cf3.8tracks.us/mix_covers/000/163/823/88074.max133w.jpg","sq100":"http://cf3.8tracks.us/mix_covers/000/163/823/88074.sq100.jpg","max200":"http://cf3.8tracks.us/mix_covers/000/163/823/88074.max200.jpg","original":"http://cf3.8tracks.us/mix_covers/000/163/823/88074.original.JPG","sq56":"http://cf3.8tracks.us/mix_covers/000/163/823/88074.sq56.jpg","sq133":"http://cf3.8tracks.us/mix_covers/000/163/823/88074.sq133.jpg"},"id":163823,"liked_by_current_user":false,"tag_list_cache":"electronic, chillwave, minimal","plays_count":190,"description":"Eight tracks including music by Gold Panda, Matthew Dear and Superpitcher.","first_published_at":"2010-10-15T22:35:47Z"},{"path":"/dp/two","slug":"two","name":"Two.","user":{"slug":"dp","followed_by_current_user":false,"id":2,"login":"dp","avatar_urls":{"sq100":"http://cf2.8tracks.us/avatars/000/000/002/24734.sq100.jpg","max200":"http://cf2.8tracks.us/avatars/000/000/002/24734.max200.jpg","sq56":"http://cf2.8tracks.us/avatars/000/000/002/24734.sq56.jpg","sq72":"http://cf2.8tracks.us/avatars/000/000/002/24734.sq72.jpg"}},"restful_url":"http://8tracks.com/mixes/139212","published":true,"cover_urls":{"max133w":"http://cf0.8tracks.us/mix_covers/000/139/212/56439.max133w.jpg","sq100":"http://cf0.8tracks.us/mix_covers/000/139/212/56439.sq100.jpg","max200":"http://cf0.8tracks.us/mix_covers/000/139/212/56439.max200.jpg","original":"http://cf0.8tracks.us/mix_covers/000/139/212/56439.original.jpg","sq56":"http://cf0.8tracks.us/mix_covers/000/139/212/56439.sq56.jpg","sq133":"http://cf0.8tracks.us/mix_covers/000/139/212/56439.sq133.jpg"},"id":139212,"liked_by_current_user":false,"tag_list_cache":"electronic, indie rock, minimal, celebratory, word","plays_count":192,"description":"Eight tracks celebrating 8tracks' 2-year anniversary, including music by Andre Sobota, Booka Shade and HEALTH.","first_published_at":"2010-08-07T21:47:37Z"},{"path":"/dp/get-hip-to-this-kindly-tip","slug":"get-hip-to-this-kindly-tip","name":"Get hip to this kindly tip ","user":{"slug":"dp","followed_by_current_user":false,"id":2,"login":"dp","avatar_urls":{"sq100":"http://cf2.8tracks.us/avatars/000/000/002/24734.sq100.jpg","max200":"http://cf2.8tracks.us/avatars/000/000/002/24734.max200.jpg","sq56":"http://cf2.8tracks.us/avatars/000/000/002/24734.sq56.jpg","sq72":"http://cf2.8tracks.us/avatars/000/000/002/24734.sq72.jpg"}},"restful_url":"http://8tracks.com/mixes/135482","published":true,"cover_urls":{"max133w":"http://cf2.8tracks.us/mix_covers/000/135/482/21191.max133w.jpg","sq100":"http://cf2.8tracks.us/mix_covers/000/135/482/21191.sq100.jpg","max200":"http://cf2.8tracks.us/mix_covers/000/135/482/21191.max200.jpg","original":"http://cf2.8tracks.us/mix_covers/000/135/482/21191.original.png","sq56":"http://cf2.8tracks.us/mix_covers/000/135/482/21191.sq56.jpg","sq133":"http://cf2.8tracks.us/mix_covers/000/135/482/21191.sq133.jpg"},"id":135482,"liked_by_current_user":false,"tag_list_cache":"rock, pop, electronic, techno, roadtrippincalifornia","plays_count":106,"description":"Driving picks for that California trip.   Get your kicks.  \r\n\r\nCraft your own mix for a road trip through the Golden State as part of our <a href=\"http://8tracks.com/roadtrippincalifornia\"> inaugural 8tracks mix contest</a>.\r\n\r\n\r\n","first_published_at":"2010-07-19T20:39:39Z"},{"path":"/dp/the-albion-chill","slug":"the-albion-chill","name":"The Albion Chill","user":{"slug":"dp","followed_by_current_user":false,"id":2,"login":"dp","avatar_urls":{"sq100":"http://cf2.8tracks.us/avatars/000/000/002/24734.sq100.jpg","max200":"http://cf2.8tracks.us/avatars/000/000/002/24734.max200.jpg","sq56":"http://cf2.8tracks.us/avatars/000/000/002/24734.sq56.jpg","sq72":"http://cf2.8tracks.us/avatars/000/000/002/24734.sq72.jpg"}},"restful_url":"http://8tracks.com/mixes/111610","published":true,"cover_urls":{"max133w":"http://cf2.8tracks.us/mix_covers/000/111/610/98445.max133w.jpg","sq100":"http://cf2.8tracks.us/mix_covers/000/111/610/98445.sq100.jpg","max200":"http://cf2.8tracks.us/mix_covers/000/111/610/98445.max200.jpg","original":"http://cf2.8tracks.us/mix_covers/000/111/610/98445.original.jpg","sq56":"http://cf2.8tracks.us/mix_covers/000/111/610/98445.sq56.jpg","sq133":"http://cf2.8tracks.us/mix_covers/000/111/610/98445.sq133.jpg"},"id":111610,"liked_by_current_user":false,"tag_list_cache":"trip hop, chill, electronic","plays_count":204,"description":"Twelve kickback tracks from 24 months (2000-01) on Albion Street in SF, including music by Air, DJ Shadow and Stardust.  \r\n\r\nEarly evenings preparing for a night out.","first_published_at":"2010-04-28T09:41:21Z"},{"path":"/dp/giant-value","slug":"giant-value","name":"Giant value","user":{"slug":"dp","followed_by_current_user":false,"id":2,"login":"dp","avatar_urls":{"sq100":"http://cf2.8tracks.us/avatars/000/000/002/24734.sq100.jpg","max200":"http://cf2.8tracks.us/avatars/000/000/002/24734.max200.jpg","sq56":"http://cf2.8tracks.us/avatars/000/000/002/24734.sq56.jpg","sq72":"http://cf2.8tracks.us/avatars/000/000/002/24734.sq72.jpg"}},"restful_url":"http://8tracks.com/mixes/91255","published":true,"cover_urls":{"max133w":"http://cf3.8tracks.us/mix_covers/000/091/255/2500.max133w.jpg","sq100":"http://cf3.8tracks.us/mix_covers/000/091/255/2500.sq100.jpg","max200":"http://cf3.8tracks.us/mix_covers/000/091/255/2500.max200.jpg","original":"http://cf3.8tracks.us/mix_covers/000/091/255/2500.original.JPG","sq56":"http://cf3.8tracks.us/mix_covers/000/091/255/2500.sq56.jpg","sq133":"http://cf3.8tracks.us/mix_covers/000/091/255/2500.sq133.jpg"},"id":91255,"liked_by_current_user":false,"tag_list_cache":"electronic, techno, electro","plays_count":258,"description":"More for your money.\r\n\r\nEight tracks including music by Fever Ray, Massive Attack and Paul Kalkbrenner.","first_published_at":"2010-02-24T23:54:35Z"},{"path":"/dp/harlem-strut","slug":"harlem-strut","name":"Harlem Strut","user":{"slug":"dp","followed_by_current_user":false,"id":2,"login":"dp","avatar_urls":{"sq100":"http://cf2.8tracks.us/avatars/000/000/002/24734.sq100.jpg","max200":"http://cf2.8tracks.us/avatars/000/000/002/24734.max200.jpg","sq56":"http://cf2.8tracks.us/avatars/000/000/002/24734.sq56.jpg","sq72":"http://cf2.8tracks.us/avatars/000/000/002/24734.sq72.jpg"}},"restful_url":"http://8tracks.com/mixes/80336","published":true,"cover_urls":{"max133w":"http://cf0.8tracks.us/mix_covers/000/080/336/36099.max133w.jpg","sq100":"http://cf0.8tracks.us/mix_covers/000/080/336/36099.sq100.jpg","max200":"http://cf0.8tracks.us/mix_covers/000/080/336/36099.max200.jpg","original":"http://cf0.8tracks.us/mix_covers/000/080/336/36099.original.jpg","sq56":"http://cf0.8tracks.us/mix_covers/000/080/336/36099.sq56.jpg","sq133":"http://cf0.8tracks.us/mix_covers/000/080/336/36099.sq133.jpg"},"id":80336,"liked_by_current_user":false,"tag_list_cache":"blues, jazz","plays_count":104,"description":"Music that Mario Bauz\u00e1 would likely have heard in New York City when he first visited from Cuba, in 1927, at the peak of the Jazz Age.  Selections by Tony Fletcher, based on the first chapter of All Hopped Up and Ready to Go: Music from the Streets of New York 1927-77 http://tinyurl.com/yd4t9va\r\n\r\nTen tracks including music by Bessie Smith with Louis Armstrong, Bix Beiderbecke (cornet) et Paul Whiteman (direction), and Charlie Johnson's Original Paradise Ten.","first_published_at":"2010-01-25T21:00:30Z"},{"path":"/dp/the-8tracks-best-of-2009-meta-mix","slug":"the-8tracks-best-of-2009-meta-mix","name":"The 8tracks best of 2009 meta-mix","user":{"slug":"dp","followed_by_current_user":false,"id":2,"login":"dp","avatar_urls":{"sq100":"http://cf2.8tracks.us/avatars/000/000/002/24734.sq100.jpg","max200":"http://cf2.8tracks.us/avatars/000/000/002/24734.max200.jpg","sq56":"http://cf2.8tracks.us/avatars/000/000/002/24734.sq56.jpg","sq72":"http://cf2.8tracks.us/avatars/000/000/002/24734.sq72.jpg"}},"restful_url":"http://8tracks.com/mixes/72948","published":true,"cover_urls":{"max133w":"http://cf0.8tracks.us/mix_covers/000/072/948/7899.max133w.jpg","sq100":"http://cf0.8tracks.us/mix_covers/000/072/948/7899.sq100.jpg","max200":"http://cf0.8tracks.us/mix_covers/000/072/948/7899.max200.jpg","original":"http://cf0.8tracks.us/mix_covers/000/072/948/7899.original.jpg","sq56":"http://cf0.8tracks.us/mix_covers/000/072/948/7899.sq56.jpg","sq133":"http://cf0.8tracks.us/mix_covers/000/072/948/7899.sq133.jpg"},"id":72948,"liked_by_current_user":false,"tag_list_cache":"alternative rock, rock, pop, best of 2009","plays_count":999,"description":"A countdown of the top 25 tracks across all \"best of 2009\" mixes on 8tracks.\r\n\r\nTracks selected based on the number of mixes in which they were included and the aggregate play count of those mixes.\r\n\r\nIncludes music by Animal Collective, Phoenix and Bat for Lashes.\r\n","first_published_at":"2009-12-31T08:26:06Z"},{"path":"/dp/favorites","slug":"favorites","name":"Favorites","user":{"slug":"dp","followed_by_current_user":false,"id":2,"login":"dp","avatar_urls":{"sq100":"http://cf2.8tracks.us/avatars/000/000/002/24734.sq100.jpg","max200":"http://cf2.8tracks.us/avatars/000/000/002/24734.max200.jpg","sq56":"http://cf2.8tracks.us/avatars/000/000/002/24734.sq56.jpg","sq72":"http://cf2.8tracks.us/avatars/000/000/002/24734.sq72.jpg"}},"restful_url":"http://8tracks.com/mixes/72930","published":true,"cover_urls":{"max133w":"http://cf2.8tracks.us/mix_covers/000/072/930/88510.max133w.jpg","sq100":"http://cf2.8tracks.us/mix_covers/000/072/930/88510.sq100.jpg","max200":"http://cf2.8tracks.us/mix_covers/000/072/930/88510.max200.jpg","original":"http://cf2.8tracks.us/mix_covers/000/072/930/88510.original.jpg","sq56":"http://cf2.8tracks.us/mix_covers/000/072/930/88510.sq56.jpg","sq133":"http://cf2.8tracks.us/mix_covers/000/072/930/88510.sq133.jpg"},"id":72930,"liked_by_current_user":false,"tag_list_cache":"electronic, electro, minimal, synthpop, best of 2009","plays_count":174,"description":"Eight tracks including music by Dan Deacon, Fuck Buttons and Gui Boratto.  \r\n\r\nThere's some heavy overlap with my earlier mixes this year, but I've only included tracks released during 2009.","first_published_at":"2009-12-31T06:53:51Z"},{"path":"/dp/pitchfork-s-best-of-2009","slug":"pitchfork-s-best-of-2009","name":"Pitchfork's Best of 2009","user":{"slug":"dp","followed_by_current_user":false,"id":2,"login":"dp","avatar_urls":{"sq100":"http://cf2.8tracks.us/avatars/000/000/002/24734.sq100.jpg","max200":"http://cf2.8tracks.us/avatars/000/000/002/24734.max200.jpg","sq56":"http://cf2.8tracks.us/avatars/000/000/002/24734.sq56.jpg","sq72":"http://cf2.8tracks.us/avatars/000/000/002/24734.sq72.jpg"}},"restful_url":"http://8tracks.com/mixes/71131","published":true,"cover_urls":{"max133w":"http://cf3.8tracks.us/mix_covers/000/071/131/43164.max133w.jpg","sq100":"http://cf3.8tracks.us/mix_covers/000/071/131/43164.sq100.jpg","max200":"http://cf3.8tracks.us/mix_covers/000/071/131/43164.max200.jpg","original":"http://cf3.8tracks.us/mix_covers/000/071/131/43164.original.jpg","sq56":"http://cf3.8tracks.us/mix_covers/000/071/131/43164.sq56.jpg","sq133":"http://cf3.8tracks.us/mix_covers/000/071/131/43164.sq133.jpg"},"id":71131,"liked_by_current_user":false,"tag_list_cache":"indie rock, pop, best of 2009","plays_count":339,"description":"A countdown of the top 10 tracks of 2009 as selected by Pitchfork staff, including music by Animal Collective, Bat For Lashes and Big Boi.\r\n\r\nCheck out the reviews here:  http://tinyurl.com/ycf9omv","first_published_at":"2009-12-23T08:58:12Z"},{"path":"/dp/welcome","slug":"welcome","name":"Welcome","user":{"slug":"dp","followed_by_current_user":false,"id":2,"login":"dp","avatar_urls":{"sq100":"http://cf2.8tracks.us/avatars/000/000/002/24734.sq100.jpg","max200":"http://cf2.8tracks.us/avatars/000/000/002/24734.max200.jpg","sq56":"http://cf2.8tracks.us/avatars/000/000/002/24734.sq56.jpg","sq72":"http://cf2.8tracks.us/avatars/000/000/002/24734.sq72.jpg"}},"restful_url":"http://8tracks.com/mixes/61156","published":true,"cover_urls":{"max133w":"http://cf0.8tracks.us/mix_covers/000/061/156/39399.max133w.jpg","sq100":"http://cf0.8tracks.us/mix_covers/000/061/156/39399.sq100.jpg","max200":"http://cf0.8tracks.us/mix_covers/000/061/156/39399.max200.jpg","original":"http://cf0.8tracks.us/mix_covers/000/061/156/39399.original.jpg","sq56":"http://cf0.8tracks.us/mix_covers/000/061/156/39399.sq56.jpg","sq133":"http://cf0.8tracks.us/mix_covers/000/061/156/39399.sq133.jpg"},"id":61156,"liked_by_current_user":false,"tag_list_cache":"electronic, techno, lo-fi","plays_count":147,"description":"Eight tracks including music by Akzidenz Grotesk, DJ Hell and F*** Buttons.","first_published_at":"2009-11-14T03:59:50Z"}]}

@@ GET http://api.8tracks.com/sets/new.json
HTTP/1.1 200 OK
Content-Length: 91
Content-Type: application/json; charset=utf-8

{"notices":null,"status":"200 OK","logged_in":false,"errors":null,"play_token":"227974697"}

@@ GET http://api.8tracks.com/sets/227974697/play.json?mix_id=163823
HTTP/1.1 200 OK
Content-Length: 349
Content-Type: application/json; charset=utf-8

{"notices":null,"status":"200 OK","logged_in":false,"errors":null,"set":{"at_beginning":true,"at_end":false,"skip_allowed":true,"track":{"performer":"Gold Panda","url":"http://8tracks.s3.amazonaws.com/tf/001/073/801/73327.64k.m4a","year":null,"faved_by_current_user":false,"release_name":"Lucky Shiner","name":"You","id":1073801,"play_duration":0}}}

@@ GET http://api.8tracks.com/sets/227974697/next.json?mix_id=163823
HTTP/1.1 200 OK
Content-Length: 356
Content-Type: application/json; charset=utf-8

{"notices":null,"status":"200 OK","logged_in":false,"errors":null,"set":{"at_beginning":false,"at_end":false,"skip_allowed":true,"track":{"performer":"Matthew Dear","url":"http://8tracks.s3.amazonaws.com/tf/001/073/797/26292.64k.m4a","year":null,"faved_by_current_user":false,"release_name":"Black City","name":"Slowdance","id":1073797,"play_duration":0}}}

@@ GET http://api.8tracks.com/sets/227974697/skip.json?mix_id=163823
HTTP/1.1 200 OK
Content-Length: 359
Content-Type: application/json; charset=utf-8

{"notices":null,"status":"200 OK","logged_in":false,"errors":null,"set":{"at_beginning":false,"at_end":false,"skip_allowed":true,"track":{"performer":"Superpitcher","url":"http://8tracks.s3.amazonaws.com/tf/001/073/802/45260.64k.m4a","year":null,"faved_by_current_user":false,"release_name":"Kilimanjaro","name":"Country Boy","id":1073802,"play_duration":0}}}

@@ GET http://api.8tracks.com/sets/227974697/skip.json?mix_id=163823 (2)
HTTP/1.1 200 OK
Content-Length: 374
Content-Type: application/json; charset=utf-8

{"notices":null,"status":"200 OK","logged_in":false,"errors":null,"set":{"at_beginning":false,"at_end":false,"skip_allowed":false,"track":{"performer":"Elephant & Castle","url":"http://8tracks.s3.amazonaws.com/tf/001/088/424/29945.64k.m4a","year":2010,"faved_by_current_user":false,"release_name":"GreyArea","name":"GreyArea (Houses Remix)","id":1088424,"play_duration":0}}}

@@ GET http://api.8tracks.com/sets/227974697/skip.json?mix_id=163823 (3)
HTTP/1.1 403 Forbidden
Content-Length: 193
Content-Type: application/json; charset=utf-8

{"notices":["Apologies for the inconvenience, but our music license requires us to limit the number of tracks you may skip each hour."],"status":"403 Forbidden","logged_in":false,"errors":null}

@@ GET http://api.8tracks.com/sets/227974697/next.json?mix_id=163823 (2)
HTTP/1.1 200 OK
Content-Length: 355
Content-Type: application/json; charset=utf-8

{"notices":null,"status":"200 OK","logged_in":false,"errors":null,"set":{"at_beginning":false,"at_end":false,"skip_allowed":false,"track":{"performer":"Superpitcher","url":"http://8tracks.s3.amazonaws.com/tf/001/073/799/24044.64k.m4a","year":null,"faved_by_current_user":false,"release_name":"Kilimanjaro","name":"Joanna","id":1073799,"play_duration":0}}}

@@ GET http://api.8tracks.com/sets/227974697/next.json?mix_id=163823 (3)
HTTP/1.1 200 OK
Content-Length: 360
Content-Type: application/json; charset=utf-8

{"notices":null,"status":"200 OK","logged_in":false,"errors":null,"set":{"at_beginning":false,"at_end":false,"skip_allowed":false,"track":{"performer":"Gold Panda","url":"http://8tracks.s3.amazonaws.com/tf/001/073/805/78746.64k.m4a","year":null,"faved_by_current_user":false,"release_name":"Lucky Shiner","name":"Snow & Taxis","id":1073805,"play_duration":0}}}

@@ GET http://api.8tracks.com/sets/227974697/next.json?mix_id=163823 (4)
HTTP/1.1 200 OK
Content-Length: 374
Content-Type: application/json; charset=utf-8

{"notices":null,"status":"200 OK","logged_in":false,"errors":null,"set":{"at_beginning":false,"at_end":false,"skip_allowed":false,"track":{"performer":"The Field","url":"http://8tracks.s3.amazonaws.com/tf/001/088/406/70845.64k.m4a","year":2007,"faved_by_current_user":false,"release_name":"From Here We Go Sublime","name":"A Paw In My Face","id":1088406,"play_duration":0}}}

@@ GET http://api.8tracks.com/sets/227974697/next.json?mix_id=163823 (5)
HTTP/1.1 200 OK
Content-Length: 393
Content-Type: application/json; charset=utf-8

{"notices":null,"status":"200 OK","logged_in":false,"errors":null,"set":{"at_beginning":false,"at_end":false,"skip_allowed":false,"track":{"performer":"Prosumer & Murat Tepeli","url":"http://8tracks.s3.amazonaws.com/tf/001/073/798/90718.64k.m4a","year":null,"faved_by_current_user":false,"release_name":"Serenity","name":"Makes Me Wanna Dance (Vinyl Version)","id":1073798,"play_duration":0}}}

@@ GET http://api.8tracks.com/sets/227974697/next.json?mix_id=163823 (6)
HTTP/1.1 200 OK
Content-Length: 141
Content-Type: application/json; charset=utf-8

{"notices":null,"status":"200 OK","logged_in":false,"errors":null,"set":{"at_beginning":false,"at_end":true,"skip_allowed":false,"track":{}}}

