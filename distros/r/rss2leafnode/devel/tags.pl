#!/usr/bin/perl -w

# Copyright 2010, 2011 Kevin Ryde
#
# This file is part of RSS2Leafnode.
#
# RSS2Leafnode is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# RSS2Leafnode is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with RSS2Leafnode.  If not, see <http://www.gnu.org/licenses/>.

use 5.004;
use strict;
use warnings;
use App::RSS2Leafnode;
use URI;
use URI::file;
use Getopt::Long;

use FindBin;
my $progname = $FindBin::Script;

# uncomment this to run the ### lines
use Smart::Comments;

my $r2l = App::RSS2Leafnode->new
  (
   verbose => 1,
  );


my @uris = map {URI->new($_,'file')} @ARGV;
if (! @uris) {
  @uris = map {URI::file->new($_)} grep {!/~$/} glob('samp/*');
}

my %known =
  map {;($_=>1)}
  qw(
      /channel
      /channel/cloud
      /channel/link
      /channel/docs
      /channel/generator
      /channel/rating
      /channel/id
      /channel/description
      /channel/tagline
      /channel/info      --atom-something-freeform
      /channel/itunes:summary
      /channel/item/dc:audience
      /channel/feedburner:info
      /channel/item/sitemap:priority
      /channel/item/sitemap:changefreq

      /channel/language
      /channel/dc:language
      /channel/item/language
      /channel/item/dc:language

      /channel/copyright
      /channel/rights
      /channel/dc:rights
      /channel/dc:license
      /channel/creativeCommons:license
      /channel/item/dc:rights
      /channel/item/dc:license
      /channel/item/creativeCommons:license
      /channel/item/media:credit   --nothing-much-in-this-one


      --feedburner-junk
      /channel/feedburner:feedFlare

      --cap-bits
      /channel/item/cap:severity

      --geo-location
      /channel/item/geo:lat
      /channel/item/geo:long
      /channel/item/geo:alt
      /channel/item/geo:Point
      /channel/item/geo:Point/geo:lat
      /channel/item/geo:Point/geo:long

      --dates
      /channel/dc:date
      /channel/lastBuildDate
      /channel/pubDate
      /channel/updated
      /channel/modified
      /channel/item/dc:date
      /channel/item/pubDate
      /channel/item/updated
      /channel/item/published
      /channel/item/modified
      /channel/item/created
      /channel/item/issued

      --author-etc
      /channel/author
      /channel/author/name   --atom
      /channel/author/uri    --atom
      /channel/author/url    --atom-typo-maybe
      /channel/author/email  --atom
      /channel/managingEditor
      /channel/webMaster
      /channel/dc:publisher
      /channel/dc:creator
      /channel/itunes:author
      --
      /channel/item/author
      /channel/item/author/name   --atom
      /channel/item/author/uri    --atom
      /channel/item/author/url    --atom-typo-maybe
      /channel/item/author/email  --atom
      /channel/item/author/gd:extendedProperty  --good-dinner
      /channel/item/dc:creator
      /channel/item/dc:publisher
      /channel/item/wiki:username
      /channel/item/itunes:author
      /channel/item/dc:contributor
      /channel/item/dc:contributor/rdf:Description
      /channel/item/dc:contributor/rdf:Description/rdf:value
      --
      /channel/item/contributor        --atom
      /channel/item/contributor/name
      /channel/item/contributor/uri
      /channel/item/contributor/url    --atom-typo-maybe
      /channel/item/contributor/email

      --rdf-structure
      /channel/items
      /channel/items/rdf:Seq
      /channel/items/rdf:Seq/rdf:li

      --images
      /channel/itunes:owner
      /channel/itunes:owner/itunes:name
      /channel/itunes:owner/itunes:email
      /channel/itunes:image
      /channel/item/image

      --ttl-and-skip-periods
      /channel/skipDays
      /channel/skipDays/day
      /channel/skipHours
      /channel/skipHours/hour
      /channel/ttl
      /channel/syn:updateBase
      /channel/syn:updatePeriod
      /channel/syn:updateFrequency

      /channel/logo
      /channel/icon
      /channel/item/media:thumbnail
      /channel/image
      /channel/image/url
      /channel/image/width
      /channel/image/height
      /channel/image/title
      /channel/image/link
      /channel/image/description

      /channel/textInput
      /channel/textInput/description
      /channel/textInput/link
      /channel/textInput/name
      /channel/textInput/title
      /channel/textinput
      /channel/textinput/title
      /channel/textinput/description
      /channel/textinput/name
      /channel/textinput/link

      /channel/openSearch:totalResults
      /channel/openSearch:startIndex
      /channel/openSearch:itemsPerPage

      -------
      /channel/item
      /channel/item/source

      --title
      /channel/title
      /channel/dc:subject
      /channel/subtitle
      /channel/itunes:subtitle
      --
      /channel/item/dc:subject
      /channel/item/summary
      /channel/item/title
      /channel/item/itunes:title
      /channel/item/itunes:subtitle

      --body
      /channel/item/description
      /channel/item/dc:description
      /channel/item/itunes:summary
      /channel/item/content:encoded

      --identifiers
      /channel/item/guid
      /channel/item/id     --atom

      --links
      /channel/item/link
      /channel/item/enclosure
      /channel/item/comments
      /channel/item/wfw:comment
      /channel/item/wfw:commentRss
      /channel/item/slash:comments
      /channel/item/slash:hit_parade
      /channel/item/thr:total
      /channel/item/content  --atom
      /channel/item/wiki:diff
      /channel/item/itunes:duration
      /channel/item/thr:in-reply-to

      /channel/category
      /channel/itunes:category
      /channel/itunes:category/itunes:category
      --
      /channel/item/category
      /channel/item/itunes:keywords
      /channel/item/media:keywords
      /channel/item/slash:section

      /channel/wiki:interwiki
      /channel/wiki:interwiki/rdf:Description
      /channel/wiki:interwiki/rdf:Description/rdf:value
      /channel/item/wiki:version
      /channel/item/wiki:status
      /channel/item/wiki:importance
      /channel/item/wiki:history

      --weather
      /channel/item/w:current
      /channel/item/w:forecast
      /channel/yweather:location
      /channel/yweather:units
      /channel/yweather:wind
      /channel/yweather:atmosphere
      /channel/yweather:astronomy
      /channel/item/yweather:condition
      /channel/item/yweather:forecast

      --central-bank
      /channel/item/cb:statistics
      /channel/item/cb:statistics/cb:country
      /channel/item/cb:statistics/cb:institutionAbbrev
      /channel/item/cb:statistics/cb:exchangeRate
      /channel/item/cb:statistics/cb:exchangeRate/cb:value
      /channel/item/cb:statistics/cb:exchangeRate/cb:baseCurrency
      /channel/item/cb:statistics/cb:exchangeRate/cb:targetCurrency
      /channel/item/cb:statistics/cb:exchangeRate/cb:rateType
      /channel/item/cb:statistics/cb:exchangeRate/cb:observationPeriod
      /channel/item/cb:speech
      /channel/item/cb:speech/cb:simpleTitle
      /channel/item/cb:speech/cb:occurrenceDate
      /channel/item/cb:speech/cb:person
      /channel/item/cb:speech/cb:person/cb:givenName
      /channel/item/cb:speech/cb:person/cb:surname
      /channel/item/cb:speech/cb:person/cb:personalTitle
      /channel/item/cb:speech/cb:person/cb:nameAsWritten
      /channel/item/cb:speech/cb:person/cb:role
      /channel/item/cb:speech/cb:person/cb:role/cb:jobTitle
      /channel/item/cb:speech/cb:person/cb:role/cb:affiliation
      /channel/item/cb:speech/cb:venue

   );
# ### %known

foreach my $uri (@uris) {
  if ($uri->isa('URI::file')) {
    $uri = URI->new_abs ($uri, URI::file->cwd);
  }
  print "$uri\n";
  my $resp = $r2l->ua->get($uri);
  if (! $resp->is_success) {
    print "  ",$resp->status_line;
    next;
  }
  my $xml = $resp->decoded_content (charset => 'none');
  my ($twig, $err) = $r2l->twig_parse($xml);
  if ($err) {
    print "  $err\n";
    next;
  }
  my %done;
  my $root = $twig->root;
  foreach my $elt ($root->descendants) {
    next if $elt->tag =~ /^#/;
    my $path = $elt->path;
    $path =~ s{^/rss/channel}{/channel};
    $path =~ s{^/(feed|rdf:RDF)}{/channel};
    $path =~ s{^/channel/entry}{/channel/item};
    $path =~ s{^/channel/channel}{/channel};
    next if $path =~ m{/xhtml};
    next if ($known{$path} || $done{$path}++);
    print "  $path\n";
  }
}

