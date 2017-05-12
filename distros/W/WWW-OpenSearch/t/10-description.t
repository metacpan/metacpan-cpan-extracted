use strict;
use warnings;

use Test::More tests => 48;

use_ok( 'WWW::OpenSearch::Description' );

# simple 1.1 OSD
{
    my $description = q(<?xml version="1.0" encoding="UTF-8"?>
<OpenSearchDescription xmlns="http://a9.com/-/spec/opensearch/1.1/">
  <ShortName>Web Search</ShortName>
  <Description>Use Example.com to search the Web.</Description>
  <Tags>example web</Tags>
  <Contact>admin@example.com</Contact>
  <Url type="application/rss+xml" 
       template="http://example.com/?q={searchTerms}&amp;pw={startPage?}&amp;format=rss"/>
</OpenSearchDescription>
);

    my $osd = WWW::OpenSearch::Description->new( $description );
    isa_ok( $osd, 'WWW::OpenSearch::Description' );
    is( $osd->shortname, 'Web Search', 'shortname' );
    ok( !defined $osd->longname, 'longname' );
    is( $osd->description, 'Use Example.com to search the Web.',
        'description' );
    is( $osd->tags,    'example web',       'tags' );
    is( $osd->contact, 'admin@example.com', 'contact' );

    # count the urls
    is( $osd->urls, 1, 'number of url objects' );
}

# complex 1.1 OSD
{
    my $description = q(<?xml version="1.0" encoding="UTF-8"?>
<OpenSearchDescription xmlns="http://a9.com/-/spec/opensearch/1.1/">
  <ShortName>Web Search</ShortName>
  <Description>Use Example.com to search the Web.</Description>
  <Tags>example web</Tags>
  <Contact>admin@example.com</Contact>
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
  <LongName>Example.com Web Search</LongName>
  <Image height="64" width="64" type="image/png">http://example.com/websearch.png</Image>
  <Image height="16" width="16" type="image/vnd.microsoft.icon">http://example.com/websearch.ico</Image>
  <Query role="example" searchTerms="cat" />
  <Developer>Example.com Development Team</Developer>
  <Attribution>
    Search data &amp;copy; 2005, Example.com, Inc., All Rights Reserved
  </Attribution>
  <SyndicationRight>open</SyndicationRight>
  <AdultContent>false</AdultContent>
  <Language>en-us</Language>
  <OutputEncoding>UTF-8</OutputEncoding>
  <InputEncoding>UTF-8</InputEncoding>
</OpenSearchDescription>
);

    my $osd = WWW::OpenSearch::Description->new( $description );
    isa_ok( $osd, 'WWW::OpenSearch::Description' );
    is( $osd->shortname, 'Web Search',             'shortname' );
    is( $osd->longname,  'Example.com Web Search', 'longname' );
    is( $osd->description, 'Use Example.com to search the Web.',
        'description' );
    is( $osd->tags,      'example web',                  'tags' );
    is( $osd->contact,   'admin@example.com',            'contact' );
    is( $osd->developer, 'Example.com Development Team', 'developer' );
    is( $osd->attribution, '
    Search data &copy; 2005, Example.com, Inc., All Rights Reserved
  ', 'attribution'
    );
    is( $osd->inputencoding,    'UTF-8', 'inputencoding' );
    is( $osd->outputencoding,   'UTF-8', 'outputencoding' );
    is( $osd->language,         'en-us', 'language' );
    is( $osd->adultcontent,     'false', 'adultcontent' );
    is( $osd->syndicationright, 'open',  'syndicationright' );

    my $queries = $osd->query;
    is( scalar @$queries,             1,         'number of query objects' );
    is( $queries->[ 0 ]->role,        'example', 'role' );
    is( $queries->[ 0 ]->searchTerms, 'cat',     'searchTerms' );

    my $images = $osd->image;
    is( scalar @$images,        2,           'number of image objects' );
    is( $images->[ 0 ]->height, 64,          'height' );
    is( $images->[ 0 ]->width,  64,          'width' );
    is( $images->[ 0 ]->type,   'image/png', 'content type' );
    is( $images->[ 0 ]->url, 'http://example.com/websearch.png', 'url' );
    is( $images->[ 1 ]->height, 16,                         'height' );
    is( $images->[ 1 ]->width,  16,                         'width' );
    is( $images->[ 1 ]->type,   'image/vnd.microsoft.icon', 'content type' );
    is( $images->[ 1 ]->url, 'http://example.com/websearch.ico', 'url' );

    # count the urls
    is( $osd->urls, 3, 'number of url objects' );
}

# 1.0 OSD
{
    my $description = q(<?xml version="1.0" encoding="UTF-8"?>
<OpenSearchDescription xmlns="http://a9.com/-/spec/opensearchdescription/1.0/">
  <Url>http://www.unto.net/aws?q={searchTerms}&amp;searchindex=Electronics
   &amp;flavor=osrss&amp;itempage={startPage}</Url>
  <Format>http://a9.com/-/spec/opensearchrss/1.0/</Format>
  <ShortName>Electronics</ShortName>
  <LongName>Amazon Electronics</LongName>
  <Description>Search for electronics on Amazon.com.</Description>
  <Tags>amazon electronics</Tags>
  <Image>http://www.unto.net/search/amazon_electronics.gif</Image>
  <SampleSearch>ipod</SampleSearch>
  <Developer>DeWitt Clinton</Developer>
  <Contact>dewitt@unto.net</Contact>
  <Attribution>Product and search data &amp;copy; 2005, Amazon, Inc.,
   All Rights Reserved</Attribution>
  <SyndicationRight>open</SyndicationRight>
  <AdultContent>false</AdultContent>
</OpenSearchDescription>
);

    my $osd = WWW::OpenSearch::Description->new( $description );
    isa_ok( $osd, 'WWW::OpenSearch::Description' );
    is( $osd->shortname, 'Electronics',        'shortname' );
    is( $osd->longname,  'Amazon Electronics', 'longname' );
    is( $osd->description, 'Search for electronics on Amazon.com.',
        'descrpiton' );
    is( $osd->tags,    'amazon electronics',                      'tags' );
    is( $osd->contact, 'dewitt@unto.net',                         'contact' );
    is( $osd->format,  'http://a9.com/-/spec/opensearchrss/1.0/', 'format' );
    is( $osd->image, 'http://www.unto.net/search/amazon_electronics.gif',
        'image' );
    is( $osd->samplesearch, 'ipod',           'samplesearch' );
    is( $osd->developer,    'DeWitt Clinton', 'developer' );
    is( $osd->attribution, 'Product and search data &copy; 2005, Amazon, Inc.,
   All Rights Reserved', 'attribution'
    );
    is( $osd->syndicationright, 'open',  'syndicationright' );
    is( $osd->adultcontent,     'false', 'adultcontent' );

    # count the urls
    is( $osd->urls, 1, 'urls' );
}
