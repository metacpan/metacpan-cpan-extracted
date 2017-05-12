use Test::More tests => 26;

use strict;
use warnings;

use_ok( 'WebService::Lucene::Results' );
use XML::Atom::Feed;
use HTTP::Response;
use WWW::OpenSearch;
use WWW::OpenSearch::Description;
use WWW::OpenSearch::Response;

{
    my $xml = <<'';
<?xml version="1.0" encoding="UTF-8"?>
<feed xmlns="http://www.w3.org/2005/Atom">
    <title>Test</title>
    <link href="http://localhost:8080/lucene/test/" rel="self" type="application/atom+xml"/>
    <link href="http://localhost:8080/lucene/test/?page=1" rel="first" type="application/atom+xml"/>
    <link href="http://localhost:8080/lucene/test/?page=1" rel="last" type="application/atom+xml"/>
    <updated>2006-02-24T12:29:19-04:00</updated>
    <author>
        <name>Lucene Web Service</name>
    </author>
    <id>http://localhost:8080/lucene/test/</id>
    <entry>
        <title>Test Document 1</title>
        <link href="http://localhost:8080/lucene/test/1/" rel="alternate"/>
        <updated>2006-01-26T16:37:44-04:00</updated>
        <id>http://localhost:8080/lucene/test/1/</id>
        <summary>Test Document 1</summary>
        <content type="xhtml">
            <div xmlns="http://www.w3.org/1999/xhtml">
                <dl class="xoxo">
                    <dt class="stored indexed">id</dt>
                    <dd>1</dd>
                    <dt class="stored indexed tokenized">text</dt>
                    <dd>Test Document 1</dd>
                    <dt class="stored indexed">updated</dt>
                    <dd>1138307864402</dd>
                </dl>
            </div>
        </content>
    </entry>
</feed>

    my $feed    = XML::Atom::Feed->new( \$xml );
    my $results = WebService::Lucene::Results->new_from_feed( $feed );

    isa_ok( $results, 'WebService::Lucene::Results' );
    isa_ok( $results->object, 'XML::Atom::Feed' );
    ok( !defined $results->pager );

    # iterator
    {
        my $documents = $results->documents;
        isa_ok( $documents, 'WebService::Lucene::Iterator' );
        my $count = 0;
        while ( my $doc = $documents->next ) {
            $count++;
            if ( $count == 1 ) {
                is( $doc->id,   1 );
                is( $doc->text, 'Test Document 1' );
            }
        }
        is( $count, 1 );
    }

    # list
    {
        my @documents = $results->documents;
        is( scalar @documents,     1 );
        is( $documents[ 0 ]->id,   1 );
        is( $documents[ 0 ]->text, 'Test Document 1' );
    }

    {
        my $link = $results->_get_link( 'self' );
        is( $link, 'http://localhost:8080/lucene/test/' );
    }

    {
        my $link = $results->_get_link( 'last' );
        is( $link, 'http://localhost:8080/lucene/test/?page=1' );
    }
}

{
    my $xml = <<'';
<?xml version="1.0" encoding="UTF-8"?>
<feed xmlns="http://www.w3.org/2005/Atom" xmlns:opensearch="http://a9.com/-/spec/opensearch/1.1/" xmlns:relevance="http://a9.com/-/opensearch/extensions/relevance/1.0/">
    <opensearch:totalResults>20</opensearch:totalResults>
    <opensearch:startIndex>1</opensearch:startIndex>
    <opensearch:itemsPerPage>10</opensearch:itemsPerPage>
    <opensearch:link href="http://localhost:8080/lucene/test/opensearchdescription.xml" rel="search" type="application/opensearchdescription+xml"/>
    <opensearch:Query rel="request" searchTerms="test"/>
    <opensearch:Query rel="correction" searchTerms="test_correction"/>
    <opensearch:Query rel="correction" searchTerms="test_correction2"/>
    <title>Search results for query 'test' on index 'Test Index'</title>
    <link href="http://localhost:8080/lucene/test/?query=test&amp;page=1" rel="self" type="application/atom+xml"/>
    <link href="http://localhost:8080/lucene/test/?query=test&amp;page=1" rel="first" type="application/atom+xml"/>
    <link href="http://localhost:8080/lucene/test/?query=test&amp;page=2" rel="next" type="application/atom+xml"/>
    <link href="http://localhost:8080/lucene/test/?query=test&amp;page=2" rel="last" type="application/atom+xml"/>
    <updated>2006-02-27T22:58:26-04:00</updated>
    <author>
        <name>Lucene Web Service</name>
    </author>
    <id>http://localhost:8080/lucene/test/?query=test</id>
    <entry>
        <title>Test Document 1</title>
        <link href="http://localhost:8080/lucene/test/1/" rel="alternate"/>
        <updated>2006-01-26T16:37:44-04:00</updated>
        <id>http://localhost:8080/lucene/test/1/</id>
        <summary>Test Document 1</summary>
        <relevance:score>1.0</relevance:score>
        <content type="xhtml">
            <div xmlns="http://www.w3.org/1999/xhtml">
                <dl class="xoxo">
                    <dt class="stored indexed">id</dt>
                    <dd>1</dd>
                    <dt class="stored indexed tokenized">text</dt>
                    <dd>Test Document 1</dd>
                    <dt class="stored indexed">updated</dt>
                    <dd>1138307864402</dd>
                </dl>
            </div>
        </content>
    </entry>
</feed>

    my $mock_req = bless {
        opensearch_url =>
            bless { ns => 'http://a9.com/-/spec/opensearch/1.1/' },
        'WWW::OpenSearch::Url'
        },
        'WWW::OpenSearch::Request';

    my $mock_res = HTTP::Response->new( 200 );
    $mock_res->content( $xml );
    $mock_res->request( $mock_req );

    my $mock_open_res = WWW::OpenSearch::Response->new( $mock_res );

    my $results
        = WebService::Lucene::Results->new_from_opensearch( $mock_open_res );

    isa_ok( $results, 'WebService::Lucene::Results' );

    # iterator
    {
        my $documents = $results->documents;
        isa_ok( $documents, 'WebService::Lucene::Iterator' );
        my $count = 0;
        while ( my $doc = $documents->next ) {
            $count++;
            if ( $count == 1 ) {
                is( $doc->id,        1 );
                is( $doc->text,      'Test Document 1' );
                is( $doc->relevance, '1.0' );
            }
        }
        is( $count, 1 );
    }

    # list
    {
        my @documents = $results->documents;
        is( scalar @documents,          1 );
        is( $documents[ 0 ]->id,        1 );
        is( $documents[ 0 ]->text,      'Test Document 1' );
        is( $documents[ 0 ]->relevance, '1.0' );
    }

    is( $results->suggestion, 'test_correction' );
    is_deeply( [ $results->suggestions ],
        [ qw( test_correction test_correction2 ) ] );
    isa_ok( $results->pager, 'Data::Page' );
}
