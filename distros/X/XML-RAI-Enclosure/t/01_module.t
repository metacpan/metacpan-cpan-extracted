#!/usr/bin/perl

use warnings;
use strict;
use Test::Simple tests => 15;
use XML::RAI;

eval {
	use XML::RAI::Enclosure;
};
ok($@ eq '', 'load the module');

eval {

use XML::RAI::Enclosure;

my $rai = XML::RAI->parse(q~
<rss version="2.0">
	<channel>
		<title>Perlcast</title>
		<link>http://www.joshmcadams.com/perlcast</link>
		<description>Perl News, Reviews and More.</description>
		<language>en-us</language>
		<copyright></copyright>

		<pubDate>Sat, 9 April 2005 13:59:00 +0000</pubDate>
		<lastBuildDate>Sat, 9 April 2005 13:59:00 +0000</lastBuildDate>
		<category>Podcast</category>
		<docs>http://blogs.law.harvard.edu/tech/rss</docs>
		<generator>vim</generator>
		<managingEditor>perlcast@gmail.com</managingEditor>

		<webMaster>perlcast@gmail.com</webMaster>
		<ttl>1440</ttl>
		
		<item>
			<title>Perlcast</title>
			<link>http://www.joshmcadams.com/perlcast</link>
			<description>Perl News, Reviews and More.</description>
			<pubDate>Sat, 9 April 2005 15:59:00 +0000</pubDate>
			<guid>http://www.joshmcadams.com/perlcast/all.xml</guid>
			<author>Josh McAdams</author>
			<category>Perl</category>
			<enclosure url="http://www.joshmcadams.com/perlcast/Perlcast_001.mp3" length="4507693"  type="audio/mpeg"/>
			<enclosure url="http://www.joshmcadams.com/perlcast/Perlcast_002.mp3" length="7944229"  type="audio/mpeg"/>
			<enclosure url="http://www.joshmcadams.com/perlcast/Perlcast_003.mp3" length="15127915" type="audio/mpeg"/>
			<enclosure url="http://www.joshmcadams.com/perlcast/Perlcast_004.mp3" length="6253319"  type="audio/mpeg"/>
		</item>

	</channel>
</rss>
~);

my ($item) = @{$rai->items};

my @e = XML::RAI::Enclosure->load($item);
ok(scalar @e == 4, 'enclosures returned');

ok($e[0]->parent->title eq 'Perlcast', 'item title');

ok($e[0]->url eq 'http://www.joshmcadams.com/perlcast/Perlcast_001.mp3', 'first url');
ok($e[1]->url eq 'http://www.joshmcadams.com/perlcast/Perlcast_002.mp3', 'second url');
ok($e[2]->url eq 'http://www.joshmcadams.com/perlcast/Perlcast_003.mp3', 'third url');
ok($e[3]->url eq 'http://www.joshmcadams.com/perlcast/Perlcast_004.mp3', 'fourth url');
ok($e[0]->length eq '4507693' , 'first length');
ok($e[1]->length eq '7944229' , 'second length');
ok($e[2]->length eq '15127915', 'third length');
ok($e[3]->length eq '6253319' , 'fourth length');
ok($e[0]->type eq 'audio/mpeg', 'first type');
ok($e[1]->type eq 'audio/mpeg', 'second type');
ok($e[2]->type eq 'audio/mpeg', 'third type');
ok($e[3]->type eq 'audio/mpeg', 'fourth type');

};


