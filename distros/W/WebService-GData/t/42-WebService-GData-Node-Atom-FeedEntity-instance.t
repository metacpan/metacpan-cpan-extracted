use Test::More tests => 12;
use WebService::GData::Node::Atom::FeedEntity;

my $feed = new WebService::GData::Node::Atom::FeedEntity( get_feed() );


ok( $feed->title eq 'YouTube Videos', "Title properly set." );

$feed->title("new title");

ok( $feed->title eq 'new title', "Title properly set." );

ok( $feed->id eq "tag:youtube.com,2008:videos",
    "id properly set." );

ok( $feed->etag eq 'W/\'CkICQX45cCp7ImA9Wx5XGUQ.\'', "etag properly set." );

ok( $feed->updated eq '2010-09-20T13:49:20.028Z', "updated properly set." );


ok( @{ $feed->link } == 6, "links properly set." );

ok( $feed->link->[0]->rel eq 'alternate', "first link properly set." );

ok( $feed->author->[0]->name eq 'YouTube', "author properly set." );

ok( $feed->category->[0]->scheme eq 'http://schemas.google.com/g/2005#kind',
    "category properly set." );
    
ok($feed->generator({})->uri eq 'http://gdata.youtube.com/','generator uri is properly set');
ok($feed->logo eq 'http://www.youtube.com/img/pic_youtubelogo_123x63.gif','generator uri is properly set');

$feed->logo('gif');
ok($feed->logo eq 'gif','generator uri is properly set again');
sub get_feed {

    return {
        'feed' => {
            'gd$etag'  => 'W/\'CkICQX45cCp7ImA9Wx5XGUQ.\'',
            'id'       => { '$t' => 'tag:youtube.com,2008:videos' },
            'updated'  => { '$t' => '2010-09-20T13:49:20.028Z' },
            'category' => [
                {
                    'scheme' => 'http://schemas.google.com/g/2005#kind',
                    'term'   => 'http://gdata.youtube.com/schemas/2007#video'
                }
            ],
            'title' => { '$t' => 'YouTube Videos' },
            'link'  => [
                {
                    'rel'  => 'alternate',
                    'type' => 'text/html',
                    'href' => 'http://www.youtube.com'
                },
                {
                    'rel'  => 'http://schemas.google.com/g/2005#feed',
                    'type' => 'application/atom+xml',
                    'href' => 'http://gdata.youtube.com/feeds/api/videos'
                },
                {
                    'rel'  => 'http://schemas.google.com/g/2005#batch',
                    'type' => 'application/atom+xml',
                    'href' => 'http://gdata.youtube.com/feeds/api/videos/batch'
                },
                {
                    'rel'  => 'self',
                    'type' => 'application/atom+xml',
                    'href' =>
'http://gdata.youtube.com/feeds/api/videos?alt=json&start-index=1&max-results=2'
                },
                {
                    'rel'  => 'service',
                    'type' => 'application/atomsvc+xml',
                    'href' =>
'http://gdata.youtube.com/feeds/api/videos?alt=atom-service'
                },
                {
                    'rel'  => 'next',
                    'type' => 'application/atom+xml',
                    'href' =>
'http://gdata.youtube.com/feeds/api/videos?alt=json&start-index=3&max-results=2'
                }
            ],
            'author' => [
                {
                    'name' => { '$t' => 'YouTube' },
                    'uri'  => { '$t' => 'http://www.youtube.com/' }
                }
            ],
            "logo"=> {
                '$t'=> "http://www.youtube.com/img/pic_youtubelogo_123x63.gif"
            },
            "generator"=> {
               '$t'=> "YouTube data API",
               "version"=> "2.0",
               "uri"=> "http://gdata.youtube.com/"
            }
        }
    };
}


