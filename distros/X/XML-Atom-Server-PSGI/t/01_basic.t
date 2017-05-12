use strict;
use Test::More;
use Test::Fatal;
use LWP::Protocol::PSGI;
use XML::Atom::Client;
use XML::Atom::Server::PSGI;

my $server = XML::Atom::Server::PSGI->new(
    callbacks => {
        on_password_for_user => sub {
            my ($self, $username) = @_;

            my $params = $self->request_params;
            my $foo    = $params->get('foo');
        
            if ($username eq 'foo' && $foo eq 'baz') {
                return 'bar';
            }

            return rand();
        },
        on_handle_request => sub {
            my $self = shift;
            if (! $self->authenticate) {
                return;
            }
            $self->res->body(<<'EOXML');
<?xml version="1.0" encoding="utf-8"?>
   <feed xmlns="http://www.w3.org/2005/Atom">
     <title type="text">dive into mark</title>
     <subtitle type="html">
       A &lt;em&gt;lot&lt;/em&gt; of effort
       went into making this effortless
     </subtitle>
     <updated>2005-07-11T12:29:29Z</updated>
     <id>tag:example.org,2003:3</id>
     <link rel="alternate" type="text/html"
      hreflang="en" href="http://example.org/"/>
     <link rel="self" type="application/atom+xml"
      href="http://example.org/feed.atom"/>
     <rights>Copyright (c) 2003, Mark Pilgrim</rights>
     <generator uri="http://www.example.com/" version="1.0">
       Example Toolkit
     </generator>
     <entry>
       <title>Atom draft-07 snapshot</title>
       <link rel="alternate" type="text/html"
        href="http://example.org/2005/04/02/atom"/>
       <link rel="enclosure" type="audio/mpeg" length="1337"
        href="http://example.org/audio/ph34r_my_podcast.mp3"/>
       <id>tag:example.org,2003:3.2397</id>
       <updated>2005-07-11T12:29:29Z</updated>
       <published>2003-12-13T08:29:29-04:00</published>
       <author>
         <name>Mark Pilgrim</name>
         <uri>http://example.org/</uri>
         <email>f8dy@example.com</email>
       </author>
       <contributor>
         <name>Sam Ruby</name>
       </contributor>
       <contributor>
         <name>Joe Gregorio</name>
       </contributor>
       <content type="xhtml" xml:lang="en"
        xml:base="http://diveintomark.org/">
         <div xmlns="http://www.w3.org/1999/xhtml">
           <p><i>[Update: The Atom draft is finished.]</i></p>
         </div>
       </content>
     </entry>
   </feed>
EOXML
        }
    }
);
LWP::Protocol::PSGI->register($server->psgi_app, host => "atom");

my $client = XML::Atom::Client->new;
$client->username("foo");
$client->password("bar");

for my $use_soap ( 0 .. 1 ) {
    note "use SOAP ? -> " . ($use_soap ? "YES" : "NO");
    $client->use_soap($use_soap);
    my $feed;
    is exception {
        $feed = $client->getFeed("http://atom/foo=bar/foo=baz/hoge=1");
    }, undef, "There should be no exceptions";

    if (! ok $feed) {
        diag "Error retrieving feed: " . $client->error;
    } else {
        isa_ok $feed, "XML::Atom::Feed";
    }
}

done_testing;