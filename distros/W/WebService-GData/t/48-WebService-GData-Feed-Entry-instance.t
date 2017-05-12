use Test::More tests => 14;
use WebService::GData::Feed::Entry;
use WebService::GData::Serialize;
my $entry = new WebService::GData::Feed::Entry( get_entry() );

ok( $entry->title eq "Young Turks Episode 10-07-09", "Title properly set." );

$entry->title("new title");

ok( $entry->title eq 'new title', "Title properly set." );

ok( $entry->etag eq "W/\"A0QDSX47eCp7ImA9Wx5RGUw.\"", "etag properly set." );

ok( $entry->updated eq "2010-08-27T14:29:38.000Z", "updated properly set." );

ok( $entry->published eq "2009-10-08T04:39:24.000Z",
    "published properly set." );

ok( @{ $entry->links } == 5, "links properly set." );

ok( $entry->links->[0]->rel eq 'alternate', "first link properly set." );

ok( $entry->category->[0]->scheme eq "http://schemas.google.com/g/2005#kind",
    "category properly set." );

ok( $entry->category->[1]->label eq "Shows", "category label properly set." );



ok( $entry->id eq "tag:youtube.com,2008:video:qWAY3YvHqLE",
    "id properly set." );

ok( $entry->content_type eq "application/x-shockwave-flash",
    "content_type properly set." );

ok(
    $entry->content_source eq
      "http://www.youtube.com/v/qWAY3YvHqLE?f\u003dvideos",
    "content_src properly set."
);

ok( $entry->content({})->isa('WebService::GData::Node::Atom::Content'),
    "content properly set." );

ok( $entry->author->[0]->name eq "TheYoungTurks", "author properly set." );


sub get_entry {

    return {
        'gd$etag'   => "W/\"A0QDSX47eCp7ImA9Wx5RGUw.\"",
        "id"        => { '$t' => "tag:youtube.com,2008:video:qWAY3YvHqLE" },
        "published" => { '$t' => "2009-10-08T04:39:24.000Z" },
        "updated"   => { '$t' => "2010-08-27T14:29:38.000Z" },
        "category"  => [
            {
                "scheme" => "http://schemas.google.com/g/2005#kind",
                "term"   => "http://gdata.youtube.com/schemas/2007#video"
            },
            {
                "scheme" =>
                  "http://gdata.youtube.com/schemas/2007/categories.cat",
                "term"  => "Shows",
                "label" => "Shows"
            },
            {
                "scheme" =>
                  "http://gdata.youtube.com/schemas/2007/keywords.cat",
                "term" => "the"
            },
            {
                "scheme" =>
                  "http://gdata.youtube.com/schemas/2007/keywords.cat",
                "term" => "young"
            },
            {
                "scheme" =>
                  "http://gdata.youtube.com/schemas/2007/keywords.cat",
                "term" => "turks"
            },
            {
                "scheme" =>
                  "http://gdata.youtube.com/schemas/2007/keywords.cat",
                "term" => "cenk"
            },
            {
                "scheme" =>
                  "http://gdata.youtube.com/schemas/2007/keywords.cat",
                "term" => "uygur"
            },
            {
                "scheme" =>
                  "http://gdata.youtube.com/schemas/2007/keywords.cat",
                "term" => "ana"
            },
            {
                "scheme" =>
                  "http://gdata.youtube.com/schemas/2007/keywords.cat",
                "term" => "kasparian"
            },
            {
                "scheme" =>
                  "http://gdata.youtube.com/schemas/2007/keywords.cat",
                "term" => "rush"
            },
            {
                "scheme" =>
                  "http://gdata.youtube.com/schemas/2007/keywords.cat",
                "term" => "limbaugh"
            },
            {
                "scheme" =>
                  "http://gdata.youtube.com/schemas/2007/keywords.cat",
                "term" => "rams"
            },
            {
                "scheme" =>
                  "http://gdata.youtube.com/schemas/2007/keywords.cat",
                "term" => "gohmert"
            },
            {
                "scheme" =>
                  "http://gdata.youtube.com/schemas/2007/keywords.cat",
                "term" => "sotomayor"
            },
            {
                "scheme" =>
                  "http://gdata.youtube.com/schemas/2007/keywords.cat",
                "term" => "shep"
            },
            {
                "scheme" =>
                  "http://gdata.youtube.com/schemas/2007/keywords.cat",
                "term" => "smith"
            },
            {
                "scheme" =>
                  "http://gdata.youtube.com/schemas/2007/keywords.cat",
                "term" => "obama"
            },
            {
                "scheme" =>
                  "http://gdata.youtube.com/schemas/2007/keywords.cat",
                "term" => "guns"
            },
            {
                "scheme" =>
                  "http://gdata.youtube.com/schemas/2007/keywords.cat",
                "term" => "rights"
            },
            {
                "scheme" =>
                  "http://gdata.youtube.com/schemas/2007/keywords.cat",
                "term" => "delay"
            },
            {
                "scheme" =>
                  "http://gdata.youtube.com/schemas/2007/keywords.cat",
                "term" => "cops"
            },
            {
                "scheme" =>
                  "http://gdata.youtube.com/schemas/2007/keywords.cat",
                "term" => "be"
            },
            {
                "scheme" =>
                  "http://gdata.youtube.com/schemas/2007/keywords.cat",
                "term" => "commentary"
            },
            {
                "scheme" =>
                  "http://gdata.youtube.com/schemas/2007/keywords.cat",
                "term" => "analysis"
            },
            {
                "scheme" =>
                  "http://gdata.youtube.com/schemas/2007/keywords.cat",
                "term" => "political"
            },
            {
                "scheme" =>
                  "http://gdata.youtube.com/schemas/2007/keywords.cat",
                "term" => "commercial"
            },
            {
                "scheme" =>
                  "http://gdata.youtube.com/schemas/2007/keywords.cat",
                "term" => "documentary"
            },
            {
                "scheme" =>
                  "http://gdata.youtube.com/schemas/2007/keywords.cat",
                "term" => "news"
            },
            {
                "scheme" =>
                  "http://gdata.youtube.com/schemas/2007/keywords.cat",
                "term" => "grassroots"
            },
            {
                "scheme" =>
                  "http://gdata.youtube.com/schemas/2007/keywords.cat",
                "term" => "outreach"
            }
        ],
        "title"   => { '$t' => "Young Turks Episode 10-07-09" },
        "content" => {
            "type" => "application/x-shockwave-flash",
            "src"  => "http://www.youtube.com/v/qWAY3YvHqLE?f\u003dvideos"
        },
        "link" => [
            {
                "rel"  => "alternate",
                "type" => "text/html",
                "href" => "http://www.youtube.com/watch?v\u003dqWAY3YvHqLE"
            },
            {
                "rel" =>
                  "http://gdata.youtube.com/schemas/2007#video.responses",
                "type" => "application/atom+xml",
                "href" =>
"http://gdata.youtube.com/feeds/api/videos/qWAY3YvHqLE/responses"
            },
            {
                "rel"  => "http://gdata.youtube.com/schemas/2007#video.related",
                "type" => "application/atom+xml",
                "href" =>
"http://gdata.youtube.com/feeds/api/videos/qWAY3YvHqLE/related"
            },
            {
                "rel"  => "http://gdata.youtube.com/schemas/2007#mobile",
                "type" => "text/html",
                "href" => "http://m.youtube.com/details?v\u003dqWAY3YvHqLE"
            },
            {
                "rel"  => "self",
                "type" => "application/atom+xml",
                "href" =>
                  "http://gdata.youtube.com/feeds/api/videos/qWAY3YvHqLE"
            }
        ],
        "author" => [
            {
                "name" => { '$t' => "TheYoungTurks" },
                "uri"  => {
                    '$t' =>
                      "http://gdata.youtube.com/feeds/api/users/theyoungturks"
                }
            }
        ]
    };
}
