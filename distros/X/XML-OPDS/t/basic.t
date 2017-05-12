#!perl

use strict;
use warnings;
use Test::More tests => 3;
use Test::Differences;
use XML::OPDS;
use XML::OPDS::Navigation;
use XML::OPDS::Acquisition;
use DateTime;
use DateTime::Format::RFC3339;

unified_diff;

my $updated = DateTime->new(year => 2016, month => 3, day => 1,
                            time_zone => 'Europe/Berlin');

my $root = XML::OPDS::Navigation->new(
                                      rel => 'self',
                                      title => 'Root',
                                      href => '/',
                                      updated => $updated,
                                     );
my $start = XML::OPDS::Navigation->new(
                                      rel => 'start',
                                      title => 'Root',
                                      href => '/',
                                      updated => $updated,
                                     );

my $titles = XML::OPDS::Navigation->new(
                                        title => 'Titles',
                                        description => 'texts sorted by title',
                                        href => '/titles',
                                        acquisition => 1,
                                        updated => $updated,
                                       );

my $topics = XML::OPDS::Navigation->new(
                                        title => 'Topics',
                                        description => 'texts sorted by topics',
                                        href => '/topics',
                                        updated => $updated,
                                       );

# full one
my $title_one = XML::OPDS::Acquisition->new(
                                            href => '/first/title',
                                            title => 'First title',
                                            authors => [
                                                        'pippo',
                                                        {
                                                         name => 'pallino',
                                                         uri => '/authors/pallino'
                                                        },
                                                       ],
                                            issued => '1943',
                                            publisher => 'Myself',
                                            image => '/covers/title.jpg',
                                            thumbnail => '/thumbs/title.jpg',
                                            language => 'en',
                                            updated => $updated,
                                            summary => 'Summary',
                                            description => '<div><em>Test</em><br><strong>me</strong></div>',
                                            files => [
                                                      '/first/title.epub',
                                                      '/first/title.pdf',
                                                      '/first/title.mobi',
                                                     ],
                                           );

# minimal, updated optional, but set because of the diff
my $title_two = XML::OPDS::Acquisition->new(
                                            href => '/second/title',
                                            title => 'Second title',
                                            files => [ '/second/title.epub' ],
                                            updated => $updated,
                                           );


{
    my $feed = XML::OPDS->new(navigations => [$root, $start, $titles, $topics ],
                              author => 'XML::OPDS 0.01',
                              logo => '/test.png',
                              icon => '/favicon.ico',
                             );

    ok ($feed, "Object created ok");
    my $expected =<< 'FEED';
<?xml version="1.0" encoding="UTF-8"?>
<feed xmlns="http://www.w3.org/2005/Atom">
  <id>/</id>
  <link rel="self" href="/" type="application/atom+xml;profile=opds-catalog;kind=navigation" title="Root"/>
  <link rel="start" href="/" type="application/atom+xml;profile=opds-catalog;kind=navigation" title="Root"/>
  <title>Root</title>
  <updated>2016-03-01T00:00:00+01:00</updated>
  <icon>/favicon.ico</icon>
  <logo>/test.png</logo>
  <author>
    <name>XML::OPDS 0.01</name>
    <uri>http://amusewiki.org</uri>
  </author>
  <entry>
    <title>Titles</title>
    <id>/titles</id>
    <content type="xhtml">
      <div xmlns="http://www.w3.org/1999/xhtml">texts sorted by title</div>
    </content>
    <updated>2016-03-01T00:00:00+01:00</updated>
    <link rel="subsection" href="/titles" type="application/atom+xml;profile=opds-catalog;kind=acquisition" title="Titles"/>
  </entry>
  <entry>
    <title>Topics</title>
    <id>/topics</id>
    <content type="xhtml">
      <div xmlns="http://www.w3.org/1999/xhtml">texts sorted by topics</div>
    </content>
    <updated>2016-03-01T00:00:00+01:00</updated>
    <link rel="subsection" href="/topics" type="application/atom+xml;profile=opds-catalog;kind=navigation" title="Topics"/>
  </entry>
</feed>
FEED
    eq_or_diff($feed->render, $expected, 'root feed ok');

    $titles->rel('self');
    $root->rel('up');
    $feed->navigations([$titles,$root,$start]);
    $feed->acquisitions([$title_one, $title_two]);
    my $acqu_expected =<< 'FEED';
<?xml version="1.0" encoding="UTF-8"?>
<feed xmlns="http://www.w3.org/2005/Atom">
  <id>/titles</id>
  <link rel="self" href="/titles" type="application/atom+xml;profile=opds-catalog;kind=acquisition" title="Titles"/>
  <link rel="start" href="/" type="application/atom+xml;profile=opds-catalog;kind=navigation" title="Root"/>
  <link rel="up" href="/" type="application/atom+xml;profile=opds-catalog;kind=navigation" title="Root"/>
  <title>Titles</title>
  <updated>2016-03-01T00:00:00+01:00</updated>
  <icon>/favicon.ico</icon>
  <logo>/test.png</logo>
  <author>
    <name>XML::OPDS 0.01</name>
    <uri>http://amusewiki.org</uri>
  </author>
  <fh:complete xmlns:fh="http://purl.org/syndication/history/1.0"></fh:complete>
  <entry>
    <id>/first/title</id>
    <title>First title</title>
    <updated>2016-03-01T00:00:00+01:00</updated>
    <dc:language xmlns:dc="http://purl.org/dc/elements/1.1/">en</dc:language>
    <author>
      <name>pippo</name>
    </author>
    <author>
      <name>pallino</name>
      <uri>/authors/pallino</uri>
    </author>
    <summary>Summary</summary>
    <content type="html">&lt;div&gt;&lt;em&gt;Test&lt;/em&gt;&lt;br&gt;&lt;strong&gt;me&lt;/strong&gt;&lt;/div&gt;</content>
    <link rel="http://opds-spec.org/acquisition" href="/first/title.epub" type="application/epub+zip"/>
    <link rel="http://opds-spec.org/acquisition" href="/first/title.pdf" type="application/pdf"/>
    <link rel="http://opds-spec.org/acquisition" href="/first/title.mobi" type="application/x-mobipocket-ebook"/>
    <link rel="http://opds-spec.org/image/thumbnail" href="/thumbs/title.jpg" type="image/jpeg"/>
    <link rel="http://opds-spec.org/image" href="/covers/title.jpg" type="image/jpeg"/>
  </entry>
  <entry>
    <id>/second/title</id>
    <title>Second title</title>
    <updated>2016-03-01T00:00:00+01:00</updated>
    <link rel="http://opds-spec.org/acquisition" href="/second/title.epub" type="application/epub+zip"/>
  </entry>
</feed>
FEED
    eq_or_diff($feed->render, $acqu_expected, "leaf feed works");
}

