#!perl

use strict;
use warnings;
use Test::More tests => 3;
use Test::Differences;
use Data::Dumper;
use XML::OPDS;
use DateTime;
use DateTime::Format::RFC3339;
use Data::Page;

unified_diff;

my $feed = XML::OPDS->new(prefix => 'http://amusewiki.org',
                          author => 'XML::OPDS 0.01',
                          updated => DateTime->new(year => 2016, month => 3, day => 1,
                                                   time_zone => 'Europe/Belgrade'));


$feed->add_to_navigations_new_level(
                          title => 'Root',
                          href => '/',
                         );
$feed->add_to_navigations(
                          rel => 'start',
                          title => 'Root',
                          href => '/',
                         );

$feed->add_to_navigations(
                          rel => 'search',
                          title => 'Search',
                          href => '/search',
                         );
$feed->add_to_navigations(
                          rel => 'crawlable',
                          title => 'Full',
                          href => '/crawlable',
                         );


$feed->add_to_navigations(
                          title => 'Titles',
                          description => 'texts sorted by title',
                          href => '/titles',
                          acquisition => 1,
                         );
{
    my $expected =<< 'FEED';
<?xml version="1.0" encoding="UTF-8"?>
<feed xmlns="http://www.w3.org/2005/Atom">
  <id>http://amusewiki.org/</id>
  <link rel="self" href="http://amusewiki.org/" type="application/atom+xml;profile=opds-catalog;kind=navigation" title="Root"/>
  <link rel="http://opds-spec.org/crawlable" href="http://amusewiki.org/crawlable" type="application/atom+xml;profile=opds-catalog;kind=navigation" title="Full"/>
  <link rel="search" href="http://amusewiki.org/search" type="application/opensearchdescription+xml" title="Search"/>
  <link rel="start" href="http://amusewiki.org/" type="application/atom+xml;profile=opds-catalog;kind=navigation" title="Root"/>
  <title>Root</title>
  <updated>2016-03-01T00:00:00+01:00</updated>
  <author>
    <name>XML::OPDS 0.01</name>
    <uri>http://amusewiki.org</uri>
  </author>
  <entry>
    <title>Titles</title>
    <id>http://amusewiki.org/titles</id>
    <content type="xhtml">
      <div xmlns="http://www.w3.org/1999/xhtml">texts sorted by title</div>
    </content>
    <updated>2016-03-01T00:00:00+01:00</updated>
    <link rel="subsection" href="http://amusewiki.org/titles" type="application/atom+xml;profile=opds-catalog;kind=acquisition" title="Titles"/>
  </entry>
</feed>
FEED
    eq_or_diff($feed->render, $expected, "prefixes ok");
}

$feed->add_to_navigations_new_level(
                          title => 'Titles',
                          description => 'texts sorted by title',
                          href => '/titles',
                          acquisition => 1,
                         );
$feed->add_to_navigations(
                          rel => 'next',
                          title => 'Titles',
                          description => 'texts sorted by title',
                          href => '/titles/2',
                          acquisition => 1,
                         );

$feed->add_to_acquisitions(
                           href => '/second/title',
                           title => 'Second title',
                           files => [ '/second/title.epub' ],
                           image => '/path/myimage.png',
                           thumbnail => '/path/to/thumbnail.png',
                           description => 'blablabla',
                          );


{
    my $expected =<< 'FEED';
<?xml version="1.0" encoding="UTF-8"?>
<feed xmlns="http://www.w3.org/2005/Atom">
  <id>http://amusewiki.org/titles</id>
  <link rel="self" href="http://amusewiki.org/titles" type="application/atom+xml;profile=opds-catalog;kind=acquisition" title="Titles"/>
  <link rel="http://opds-spec.org/crawlable" href="http://amusewiki.org/crawlable" type="application/atom+xml;profile=opds-catalog;kind=navigation" title="Full"/>
  <link rel="next" href="http://amusewiki.org/titles/2" type="application/atom+xml;profile=opds-catalog;kind=acquisition" title="Titles"/>
  <link rel="search" href="http://amusewiki.org/search" type="application/opensearchdescription+xml" title="Search"/>
  <link rel="start" href="http://amusewiki.org/" type="application/atom+xml;profile=opds-catalog;kind=navigation" title="Root"/>
  <link rel="up" href="http://amusewiki.org/" type="application/atom+xml;profile=opds-catalog;kind=navigation" title="Root"/>
  <title>Titles</title>
  <updated>2016-03-01T00:00:00+01:00</updated>
  <author>
    <name>XML::OPDS 0.01</name>
    <uri>http://amusewiki.org</uri>
  </author>
  <entry>
    <id>http://amusewiki.org/second/title</id>
    <title>Second title</title>
    <updated>2016-03-01T00:00:00+01:00</updated>
    <content type="xhtml">
      <div xmlns="http://www.w3.org/1999/xhtml">blablabla</div>
    </content>
    <link rel="http://opds-spec.org/acquisition" href="http://amusewiki.org/second/title.epub" type="application/epub+zip"/>
    <link rel="http://opds-spec.org/image/thumbnail" href="http://amusewiki.org/path/to/thumbnail.png" type="image/png"/>
    <link rel="http://opds-spec.org/image" href="http://amusewiki.org/path/myimage.png" type="image/png"/>
  </entry>
</feed>
FEED
    eq_or_diff($feed->render, $expected, "prefixes ok");
}

{
    my $pager = Data::Page->new;
    $pager->total_entries(50);
    $pager->entries_per_page(20);
    $pager->current_page(1);
    $feed->search_result_pager($pager);
    my $expected =<< 'FEED';
<?xml version="1.0" encoding="UTF-8"?>
<feed xmlns="http://www.w3.org/2005/Atom">
  <id>http://amusewiki.org/titles</id>
  <link rel="self" href="http://amusewiki.org/titles" type="application/atom+xml;profile=opds-catalog;kind=acquisition" title="Titles"/>
  <link rel="http://opds-spec.org/crawlable" href="http://amusewiki.org/crawlable" type="application/atom+xml;profile=opds-catalog;kind=navigation" title="Full"/>
  <link rel="next" href="http://amusewiki.org/titles/2" type="application/atom+xml;profile=opds-catalog;kind=acquisition" title="Titles"/>
  <link rel="search" href="http://amusewiki.org/search" type="application/opensearchdescription+xml" title="Search"/>
  <link rel="start" href="http://amusewiki.org/" type="application/atom+xml;profile=opds-catalog;kind=navigation" title="Root"/>
  <link rel="up" href="http://amusewiki.org/" type="application/atom+xml;profile=opds-catalog;kind=navigation" title="Root"/>
  <title>Titles</title>
  <updated>2016-03-01T00:00:00+01:00</updated>
  <author>
    <name>XML::OPDS 0.01</name>
    <uri>http://amusewiki.org</uri>
  </author>
  <opensearch:totalResults xmlns:opensearch="http://a9.com/-/spec/opensearch/1.1/">50</opensearch:totalResults>
  <opensearch:startIndex xmlns:opensearch="http://a9.com/-/spec/opensearch/1.1/">1</opensearch:startIndex>
  <opensearch:itemsPerPage xmlns:opensearch="http://a9.com/-/spec/opensearch/1.1/">20</opensearch:itemsPerPage>
  <entry>
    <id>http://amusewiki.org/second/title</id>
    <title>Second title</title>
    <updated>2016-03-01T00:00:00+01:00</updated>
    <content type="xhtml">
      <div xmlns="http://www.w3.org/1999/xhtml">blablabla</div>
    </content>
    <link rel="http://opds-spec.org/acquisition" href="http://amusewiki.org/second/title.epub" type="application/epub+zip"/>
    <link rel="http://opds-spec.org/image/thumbnail" href="http://amusewiki.org/path/to/thumbnail.png" type="image/png"/>
    <link rel="http://opds-spec.org/image" href="http://amusewiki.org/path/myimage.png" type="image/png"/>
  </entry>
</feed>
FEED
    eq_or_diff($feed->render, $expected, "opensearch ok");
}
