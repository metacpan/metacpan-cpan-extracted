use Test::More tests => 9;

use strict;
use warnings;

use_ok( 'WWW::OpenSearch::Description' );
use_ok( 'WWW::OpenSearch::Request' );

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

    {
        my $req = WWW::OpenSearch::Request->new( $osd->url->[ 2 ],
            { searchTerms => 'iPod' } );
        isa_ok( $req, 'WWW::OpenSearch::Request' );
        is( lc $req->method, 'post', 'method' );
        is( $req->uri, 'https://intranet/search?format=html', 'uri' );
        is( _sort_result( $req->content ), 'c=&l=*&o=1&s=iPod', 'content' );
    }

    {
        my $req = WWW::OpenSearch::Request->new( $osd->url->[ 1 ],
            { searchTerms => 'iPod' } );
        isa_ok( $req, 'WWW::OpenSearch::Request' );
        is( lc $req->method, 'get', 'method' );
        is( $req->uri, 'http://example.com/?q=iPod&pw=1&format=atom', 'uri' );
    }
}

sub _sort_result {
    my $s = shift;
    return join( '&',
        sort { substr( $a, 0, 1 ) cmp substr( $b, 0, 1 ) }
            split( /\&/, $s ) );
}
