use strict;
use warnings;

use Test::More tests => 36;

use_ok( 'WWW::OpenSearch::Description' );
use_ok( 'WWW::OpenSearch::Url' );

{
    my $description = q(<?xml version="1.0" encoding="UTF-8"?>
<OpenSearchDescription xmlns="http://a9.com/-/spec/opensearch/1.1/">
  <Url type="application/rss+xml" 
       template="http://example.com/?q={searchTerms}&amp;pw={startPage?}&amp;format=rss"/>
</OpenSearchDescription>
);

    my $osd = WWW::OpenSearch::Description->new( $description );
    isa_ok( $osd, 'WWW::OpenSearch::Description' );
    is( $osd->version, '1.1', 'version' );
    is( $osd->ns, 'http://a9.com/-/spec/opensearch/1.1/', 'namespace' );
    is( $osd->urls, 1, 'number of urls' );

    my ( $url ) = $osd->urls;
    isa_ok( $url, 'WWW::OpenSearch::Url' );
    is( $url->type, 'application/rss+xml', 'content type' );
    is( lc $url->method, 'get', 'method' );
    is( $url->template->template,
        'http://example.com/?q={searchTerms}&pw={startPage}&format=rss',
        'template' );
    my $result
        = $url->prepare_query( { searchTerms => 'x', startPage => 1 } );
    is( $result, 'http://example.com/?q=x&pw=1&format=rss', 'prepare_query' );
}

{
    my $description = q(<?xml version="1.0" encoding="UTF-8"?>
<OpenSearchDescription xmlns="http://a9.com/-/spec/opensearch/1.1/">
  <Url type="application/rss+xml"
       template="http://example.com/?q={searchTerms}&amp;pw={startPage}&amp;format=rss"/>
  <Url type="application/atom+xml"
       template="http://example.com/?q={searchTerms}&amp;pw={startPage?}&amp;format=atom"/>
  <Url type="text/html" 
       method="post"
       template="https://intranet/search?format=html">
    <Param name="s" value="{searchTerms}"/>
    <Param name="o" value="{startIndex?}"/>
    <Param name="c" value="{itemsPerPage?}"/>
    <Param name="l" value="{language?}"/>
  </Url>
</OpenSearchDescription>
);

    my $osd = WWW::OpenSearch::Description->new( $description );
    isa_ok( $osd, 'WWW::OpenSearch::Description' );
    is( $osd->urls, 3, 'number of urls' );
    is( $osd->get_best_url, $osd->url->[ 1 ], 'get_best_url' );

    {
        my $url = $osd->url->[ 0 ];
        isa_ok( $url, 'WWW::OpenSearch::Url' );
        is( $url->type, 'application/rss+xml', 'content type' );
        is( lc $url->method, 'get', 'method' );
        is( $url->template->template,
            'http://example.com/?q={searchTerms}&pw={startPage}&format=rss',
            'template' );
    }

    {
        my $url = $osd->url->[ 1 ];
        isa_ok( $url, 'WWW::OpenSearch::Url' );
        is( $url->type, 'application/atom+xml', 'content type' );
        is( lc $url->method, 'get', 'method' );
        is( $url->template->template,
            'http://example.com/?q={searchTerms}&pw={startPage}&format=atom',
            'template'
        );
    }

    {
        my $url = $osd->url->[ 2 ];
        isa_ok( $url, 'WWW::OpenSearch::Url' );
        is( $url->type,      'text/html', 'content type' );
        is( lc $url->method, 'post',      'method' );
        is( $url->template->template, 'https://intranet/search?format=html',
            'template' );
        is_deeply(
            $url->params,
            {   s => '{searchTerms}',
                o => '{startIndex}',
                c => '{itemsPerPage}',
                l => '{language}'
            },
            'params'
        );
        my ( $result, $post ) = $url->prepare_query(
            {   searchTerms  => 'x',
                startIndex   => '1',
                itemsPerPage => 1,
                language     => 'en'
            }
        );
        is( $result,
            'https://intranet/search?format=html',
            'prepare_query (uri)'
        );
        $post = { @$post };
        is_deeply(
            $post,
            { s => 'x', o => 1, c => 1, l => 'en' },
            'prepare_query (params)'
        );
    }
}

{
    my $description = q(<?xml version="1.0" encoding="UTF-8"?>
<OpenSearchDescription xmlns="http://a9.com/-/spec/opensearchdescription/1.0/">
  <Url>http://www.unto.net/aws?q={searchTerms}&amp;searchindex=Electronics&amp;flavor=osrss&amp;itempage={startPage}</Url>
</OpenSearchDescription>
);

    my $osd = WWW::OpenSearch::Description->new( $description );
    isa_ok( $osd, 'WWW::OpenSearch::Description' );
    is( $osd->version, '1.0', 'version' );
    is( $osd->ns, 'http://a9.com/-/spec/opensearchrss/1.0/', 'namespace' );
    is( $osd->urls, 1, 'number of urls' );

    my ( $url ) = $osd->urls;
    isa_ok( $url, 'WWW::OpenSearch::Url' );
    is( lc $url->method, 'get', 'method' );
    is( $url->template->template,
        'http://www.unto.net/aws?q={searchTerms}&searchindex=Electronics&flavor=osrss&itempage={startPage}',
        'template'
    );
}

