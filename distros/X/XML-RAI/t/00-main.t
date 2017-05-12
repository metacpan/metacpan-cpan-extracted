#!perl

BEGIN { chdir 't' if -d 't' }

use strict;
use warnings;

use Test::More tests => 15;

my @mods = qw( 
                XML::RAI 
                XML::RAI::Channel 
                XML::RAI::Item 
                XML::RAI::Image 
);

#--- compiles?
map { use_ok($_) } @mods;

# we're skipping constructors because you need XML::RSS::Parser elements.
# this will get tested once we do parse.

#--- can parse "ultra funky" RSS that is valid XML
my $rss = <<FUNKYRSS;
<?xml version="1.0" encoding="iso-8859-1"?>
 <rss xmlns:dc="http://purl.org/dc/elements/1.1/"
     xmlns:tima = "http://www.timaoutloud.org/"
     xmlns="http://purl.org/rss/1.0/">
     <channel>
         <title>tima thinking outloud</title>
         <link>http://www.timaoutloud.org/</link>
         <description></description>
         <dc:language>en-us</dc:language>
     </channel>
     <item>
         <title>His and Hers Weblogs.</title>
         <description>First it was his and hers Powerbooks. Now 
         its weblogs. There goes the neighborhood.</description>
         <link>http://www.timaoutloud.org/archives/000338.html</link>
         <dc:subject>Musings</dc:subject>
         <dc:creator>tima</dc:creator>
         <dc:date>2004-01-23T12:33:22-05:00</dc:date>
         <tima:foo>40</tima:foo>
     </item>
     <item>
         <title>Commercial Music Again.</title>
         <description>Last year I made a post about music used 
         in TV commercials that I recognized and have been listening to. 
         For all the posts I made about technology and other bits of sagely
         wisdom the one on commercial music got the most traffic of any 
         each month. I need a new top post. Here are some more tunes that 
         have appeared in commercials.</description>
         <guid isPermaLink="true">
           http://www.timaoutloud.org/archives/000337.html
         </guid>
         <category>Musings</category>
         <author>tima</author>
         <pubDate>Sun, 18 Jan 2004 14:09:03 GMT</pubDate>
     </item>
     <image>
        <title>image title</title>
        <url>http://www.timaoutloud.org/image.jog</url>
        <height>40</height>
        <width>72</width>
     </image>
 </rss>
FUNKYRSS

my $rai = XML::RAI->parse_string($rss);
ok($rai && ref($rai) eq 'XML::RAI','parse return');

# should we also test the underlying XML::RSS::Parser elements?
my $channel = $rai->channel;
ok($channel && ref($channel) eq 'XML::RAI::Channel', 'has channel');
my $items = $rai->items;
ok(@$items, 'has items');
ok(scalar @$items == 2, 'item count');
my $i = 1;
map{ ok(ref($_) eq 'XML::RAI::Item', 'item type check '.$i++) } @$items;
my $image = $rai->image;
ok($image && ref($image) eq 'XML::RAI::Image', 'has image');
ok($rai->time_format, 'has time format');
$rai->time_format('EPOCH');
ok($rai->time_format eq 'EPOCH','time format set/get');

# add_mapping. 
# since its inherited by any XML::RAI::Object we only test one.
XML::RSS::Parser->register_ns_prefix('tima','http://www.timaoutloud.org/');
XML::RAI::Item->add_mapping('tima','tima:foo'); # new
XML::RAI::Item->add_mapping('source','tima:foo'); # existing
ok($items->[0]->tima == 40,'add new mapping');
ok($items->[0]->source == 40, 'append mapping');