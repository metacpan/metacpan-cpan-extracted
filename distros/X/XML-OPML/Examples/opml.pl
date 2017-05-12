#!/usr/bin/perl -w

use strict;
use XML::OPML;

# Create the OPML file

my $opml = new XML::OPML(version => '1.1');
$opml->head(
             title => 'opml test file',
             dateCreated => 'Sat 2004 02 14 09:22:00 GMT',
             dateModified => 'Sat 2004 02 14 09:22:00 GMT',
             ownerName => 'michael szul',
             ownerEmail => 'opml-dev@blogenstein.com',
             expansionState => '',
             vertScrollState => '',
             windowTop => '',
             windowLeft => '',
             windowBottom => '',
             windowRight => '',
           );
$opml->add_outline(
                   text => 'madghoul.com | the dark night of the soul',
                   description => 'Looking for something Strange?',
                   title => 'madghoul.com | the dark night of the soul',
                   type => 'rss',
                   version => 'RSS',
                   htmlurl => 'http://www.madghoul.com/ghoul/InsaneRapture/lunacy.mhtml',
                   xmlurl => 'http://www.madghoul.com/cgi-bin/fearsome/fallout/index.rss10',
                  );
$opml->add_outline(
                   text => 'opml news from opml.blogenstein.com',
                   description => '',
                   title => 'opml.blogenstein.com',
                   type => 'rss',
                   version => 'RSS',
                   htmlurl => 'http://opml.blogenstein.com',
                  );
$opml->add_outline(
                   opmlvalue => 'embed',
                   text => 'Embedded',
                   outline_one => {
                                   text => 'Embedded outline for parsing format',
                                   description => 'a long description for this embedded outline so that I can see it when debugging with ptkdb',
                                  },
                   outline_two => {
                                   text => 'Second Embedded outline for parsing opml content',
                                   description => 'thankfully parsing works without having to many tricky things',
                                  },
                  );
$opml->save('modules.opml');

# Now update the file

$opml->parse('modules.opml');
$opml->insert_outline(
                      group => "Embedded",
                      text => 'new additions to OPML',
                      description => 'more outlines',
                      title =>'a blank title',
                      type => 'rss',
                      version => 'RSS',
                      htmlurl => 'no url',
                      xmlurl => 'definitely no rss feed',
                     );
;
$opml->save('modules.opml');

