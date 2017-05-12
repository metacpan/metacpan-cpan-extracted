use Test::More tests => 9;

use strict;
use XML::Atom::Feed;
use XML::Atom::Ext::OpenSearch;

my $feed = XML::Atom::Feed->new( \*DATA );

isa_ok( $feed, 'XML::Atom::Feed' );
is( $feed->totalResults, 4230000, 'totalresults' );
is( $feed->startIndex, 21, 'startIndex' );
is( $feed->itemsPerPage, 10, 'itemsPerPage' );

my( @queries )= $feed->Query;
is( scalar @queries, 1, '1 query element' );
my $query = $queries[ 0 ];
isa_ok( $query, 'XML::Atom::Ext::OpenSearch::Query' );
is( $query->role, 'request' );
is( $query->searchTerms, 'New York History' );
is( $query->startPage, 1 );

__DATA__
<?xml version="1.0" encoding="UTF-8"?>
 <feed xmlns="http://www.w3.org/2005/Atom" 
       xmlns:opensearch="http://a9.com/-/spec/opensearch/1.1/">
   <title>Example.com Search: New York history</title> 
   <link href="http://example.com/New+York+history"/>
   <updated>2003-12-13T18:30:02Z</updated>
   <author> 
     <name>Example.com, Inc.</name>
   </author> 
   <id>urn:uuid:60a76c80-d399-11d9-b93C-0003939e0af6</id>
   <opensearch:totalResults>4230000</opensearch:totalResults>
   <opensearch:startIndex>21</opensearch:startIndex>
   <opensearch:itemsPerPage>10</opensearch:itemsPerPage>
   <opensearch:Query role="request" searchTerms="New York History" startPage="1" />
   <link rel="alternate" href="http://example.com/New+York+History?pw=3" type="text/html"/>
   <link rel="self" href="http://example.com/New+York+History?pw=3&amp;format=atom" type="application/atom+xml"/>
   <link rel="first" href="http://example.com/New+York+History?pw=1&amp;format=atom" type="application/atom+xml"/>
   <link rel="previous" href="http://example.com/New+York+History?pw=2&amp;format=atom" type="application/atom+xml"/>
   <link rel="next" href="http://example.com/New+York+History?pw=4&amp;format=atom" type="application/atom+xml"/>
   <link rel="last" href="http://example.com/New+York+History?pw=42299&amp;format=atom" type="application/atom+xml"/>
   <link rel="search" type="application/opensearchdescription+xml" href="http://example.com/opensearchdescription.xml"/>
   <entry>
     <title>New York History</title>
     <link href="http://www.columbia.edu/cu/lweb/eguids/amerihist/nyc.html"/>
     <id>urn:uuid:1225c695-cfb8-4ebb-aaaa-80da344efa6a</id>
     <updated>2003-12-13T18:30:02Z</updated>
     <content type="text">
       ... Harlem.NYC - A virtual tour and information on 
       businesses ...  with historic photos of Columbia's own New York 
       neighborhood ... Internet Resources for the City's History. ...
     </content>
   </entry>
 </feed>
