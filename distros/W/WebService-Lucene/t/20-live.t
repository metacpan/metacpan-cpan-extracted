use Test::More;

# TODO: Add error checking, and test it.

use strict;
use warnings;

plan skip_all => '$ENV{LUCENE_SERVER} not set' unless $ENV{ LUCENE_SERVER };
plan tests => 38;

use_ok( 'WebService::Lucene' );
use_ok( 'WebService::Lucene::Document' );
use_ok( 'WebService::Lucene::Exception' );

my $index_name = '_temp' . $$;
my $service    = WebService::Lucene->new( $ENV{ LUCENE_SERVER } );
isa_ok( $service, 'WebService::Lucene' );

# fetch service properties
{
    my $properties = $service->properties;
    ok( keys %$properties );
    $properties->{ $index_name } = 1;
    $service->update;
    is( $properties->{ $index_name }, 1 );
    delete $properties->{ $index_name };
    $service->update;
    ok( !defined $properties->{ $index_name } );
}

my $index = $service->create_index( $index_name );
isa_ok( $index, 'WebService::Lucene::Index' );

# fetch service document
{
    my @indices = $service->indices;
    ok( grep { $_->name eq $index_name } @indices );
    ok( $service->title );
}

# fetch index properties
{
    my $properties = $index->properties;

    # new indices have no properties!
    ok( !keys %$properties );
    $properties->{ $index_name } = 1;
    $index->update;
    is( $properties->{ $index_name }, 1 );
    delete $properties->{ $index_name };
    $index->update;
    ok( !defined $properties->{ $index_name } );
}

# fetch OSD
{
    my $os_client = $index->opensearch_client;
    isa_ok( $os_client, 'WWW::OpenSearch' );
}

# exception
{
    my $entry = eval { $index->get_document( 1 ) };
    my $e = WebService::Lucene::Exception->caught;
    isa_ok( $e, 'WebService::Lucene::Exception' );
    is( $e->response->code, '404' );
    is( $e->message, q(Document '1' not found.) );
}

my $doc = WebService::Lucene::Document->new;
isa_ok( $doc, 'WebService::Lucene::Document' );

$doc->add_keyword( id => 1 );
is( $doc->id, 1 );
$doc->add_text( foo => 'bar' );
is( $doc->foo, 'bar' );

$index->add_document( $doc );

my $doc1 = $index->get_document( 1 );
is( $doc1->id,  1 );
is( $doc1->foo, 'bar' );

# list of document
{
    my $results = $index->list;
    my @docs    = $results->documents;
    is( scalar @docs,    1 );
    is( $docs[ 0 ]->id,  1 );
    is( $docs[ 0 ]->foo, 'bar' );
}

# facets
{
    my $results = $index->facets( 'foo' );
    my @docs    = $results->documents;
    is( scalar @docs, 1 );
    my %facets = $docs[ 0 ]->facets;
    is_deeply( \%facets, { bar => 1 } );
}

# search for document
{
    my $results = $service->search( $index_name, 'bar',
        { 'lucene:defaultField' => 'foo' } );
    my @docs = $results->documents;
    is( scalar @docs,    1 );
    is( $docs[ 0 ]->id,  1 );
    is( $docs[ 0 ]->foo, 'bar' );
}

# next/prev page
{
    my $doc2 = WebService::Lucene::Document->new;
    $doc2->add_keyword( id => 2 );
    $doc2->add_text( foo => 'bar' );

    $index->add_document( $doc2 );

    my $res = $index->search( 'bar',
        { count => 1, 'lucene:defaultField' => 'foo' } );
    {
        my @docs = $res->documents;
        is( scalar @docs, 1 );
    }

    {
        $res = $res->next_page;
        my @docs = $res->documents;
        is( scalar @docs, 1 );
    }
    {
        $res = $res->previous_page;
        my @docs = $res->documents;
        is( scalar @docs, 1 );
    }

    # list
    $res = $index->list( { count => 1 } );
    {
        my @docs = $res->documents;
        is( scalar @docs, 1 );
    }

    {
        $res = $res->next_page;
        my @docs = $res->documents;
        is( scalar @docs, 1 );
    }
    {
        $res = $res->previous_page;
        my @docs = $res->documents;
        is( scalar @docs, 1 );
    }
}

$doc1->add_text( foo => 'baz' );
$doc1->update;

my $doc1u = $index->get_document( 1 );
is( $doc1u->id, 1 );
is_deeply( [ $doc1u->foo ], [ qw( bar baz ) ] );

$index->delete_document( 1 );
$index->optimize;

$service->delete_index( $index_name );
