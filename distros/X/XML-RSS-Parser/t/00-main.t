#!perl

BEGIN { chdir 't' if -d 't' }

use strict;
use warnings;

use Test::More tests => 24;

my @mods = qw( 
    XML::RSS::Parser 
    XML::RSS::Parser::Feed 
    XML::RSS::Parser::Element 
    XML::RSS::Parser::Characters
);


#--- compiles?
map { use_ok($_) } @mods;

#--- makes sure constructors works.
map { ok(ref($_->new) eq $_, "$_ constructor") } @mods;

#--- utils test

my $ns_qualify = XML::RSS::Parser->ns_qualify('foo','http://www.example.com/');
ok( $ns_qualify eq '{http://www.example.com/}foo', 'ns_qualify');

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
 </rss>
FUNKYRSS

my $p = XML::RSS::Parser->new;
my $feed = $p->parse_string($rss);
ok($feed, 'parse');
ok(ref($feed) eq 'XML::RSS::Parser::Feed','parse returns feed object');
my $rss_ns = $feed->find_rss_namespace;
ok($rss_ns eq 'http://purl.org/rss/1.0/', 'find_rss_namespace');

#--- examine feed
ok(scalar @{$feed->contents} == 1, 'channel is single child of feed');
my $channel = $feed->contents->[0];
ok($channel->name eq "{$rss_ns}channel", 'channel name');
ok(ref($channel) eq 'XML::RSS::Parser::Element','channel object type');
ok(scalar @{$channel->contents},'channel has children');
my @items = grep { $_->name eq "{$rss_ns}item" } 
    grep { ref($_) eq 'XML::RSS::Parser::Element' } 
        @{$channel->contents};
ok(@items, 'has items');
ok(scalar @items == 2, 'item count');
my ($creator) = $channel->query('//dc:creator');
ok(ref($creator) eq 'XML::RSS::Parser::Element','can find creator element' );
my $item  = $creator->parent;
my $item_creator = $item->query('dc:creator');
ok($creator eq $item_creator,'creator queries match');
ok($creator->text_content eq 'tima', 'creator is tima');
my $guid = $channel->query('//guid');
ok($guid,'can find guid also');
my $is_permalink = $guid->query('//@isPermaLink');
ok($is_permalink && $is_permalink eq 'true','attribute query');

#--- namespace registry

$p->register_ns_prefix('tima','http://www.timaoutloud.org/');
my($tima) = $feed->query('//tima:foo');
ok($tima && $tima->text_content == 40,'register_ns_prefix and query');

__END__

my $par = $guid->parent;
$guid->parent(undef);
use Data::Dumper;
warn Dumper($guid);
$guid->parent($par);
warn Dumper($guid->attribute_qnames);
