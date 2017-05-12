use Test::More tests => 4;
use WebService::GData::Node::Atom::FeedEntity;
use WebService::GData::Serialize;

my $feed = new WebService::GData::Node::Atom::FeedEntity( );

$feed->title("new title");
$feed->id("tag:youtube.com,2008:videos");
$feed->etag('W/\'CkICQX45cCp7ImA9Wx5XGUQ.\'');
$feed->updated('2010-09-20T13:49:20.028Z');
$feed->generator('perl');
$feed->generator({})->uri('http://www.perl.org/');
$feed->generator({})->version(5);
$feed->logo('http://www.youtube.com/img/pic_youtubelogo_123x63.gif');


push @{$feed->category}, {
                    'scheme' => 'http://schemas.google.com/g/2005#kind',
                    'term'   => 'http://gdata.youtube.com/schemas/2007#video'
                };
                
push @{$feed->link}, {
                    'rel'  => 'alternate',
                    'type' => 'text/html',
                    'href' => 'http://www.youtube.com'
                }; 

                 

push @{$feed->author},{name=>'shirirules',uri=>'http://www.cpan.org'};
$feed->author->[0]->name('shiriru');      

my $xml = WebService::GData::Serialize->to_xml($feed->_entity,$feed->_entity);

my $expected_xml=q[<feed xmlns="http://www.w3.org/2005/Atom" gd:etag="W/&apos;CkICQX45cCp7ImA9Wx5XGUQ.&apos;" xmlns:gd="http://schemas.google.com/g/2005">];
   $expected_xml.=q[<logo>http://www.youtube.com/img/pic_youtubelogo_123x63.gif</logo>];
   $expected_xml.=q[<generator version="5" uri="http://www.perl.org/">perl</generator>];
   $expected_xml.=q[<author><name>shiriru</name><uri>http://www.cpan.org</uri></author>];
   $expected_xml.=q[<category scheme="http://schemas.google.com/g/2005#kind" term="http://gdata.youtube.com/schemas/2007#video"/>];
   $expected_xml.=q[<id>tag:youtube.com,2008:videos</id>];
   $expected_xml.=q[<link rel="alternate" type="text/html" href="http://www.youtube.com"/>];
   $expected_xml.=q[<title>new title</title>];
   $expected_xml.=q[<updated>2010-09-20T13:49:20.028Z</updated>];
   $expected_xml.=q[</feed>];

ok($xml eq $expected_xml,'only set properties are output');


ok( $feed->link->[0]->rel eq 'alternate', "first link properly set." );

ok( $feed->author->[0]->name eq 'shiriru', "author properly set." );

ok( $feed->category->[0]->scheme eq 'http://schemas.google.com/g/2005#kind',
    "category properly set." );
