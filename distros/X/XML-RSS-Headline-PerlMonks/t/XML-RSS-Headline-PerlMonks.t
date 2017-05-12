#!/usr/bin/perl 

use strict;
use warnings;
use Test::More;

eval 'use XML::RSS::Feed';
plan( skip_all => 'XML::RSS::Feed required to test') if $@;

eval 'use XML::RSS::Feed::PerlMonks';
plan( skip_all => 'XML::RSS::Feed::PerlMonks required to test' ) if $@;

plan( test => 9 );

my $feed = XML::RSS::Feed->new(
	'url'    => 'http://perlmonks.org/?node_id=30175;xmlstyle=rss',
	'name'   => 'pm_newnodes',
	'hlobj'  => 'XML::RSS::Headline::PerlMonks',
);

isa_ok( $feed, 'XML::RSS::Feed' );

ok( $feed->parse( xml(1) ), 'Parse good perlmonks XML' );
is ( ($feed->headlines)[0]->headline, 'Question on qx', 'Test for a matching headline' );
is ( ($feed->headlines)[0]->authortitle, 'narashima', 'Test for a matching authortitle' );
is ( ($feed->headlines)[0]->node_id, '582160', 'Test for a matching node_id' );

my $feed_missing_data = XML::RSS::Feed->new(
	'url'    => 'http://perlmonks.org/?node_id=30175;xmlstyle=rss',
	'name'   => 'pm_newnodes',
	'hlobj'  => 'XML::RSS::Headline::PerlMonks',
);

isa_ok( $feed_missing_data, 'XML::RSS::Feed' );

ok( $feed_missing_data->parse( xml(2) ), 'Parse good perlmonks XML' );
is ( ($feed_missing_data->headlines)[0]->headline, 'Question on qx', 'Test for a matching headline' );
is ( ($feed_missing_data->headlines)[0]->authortitle, 'Unknown', 'Test for a missing authortitle' );

sub xml {
	my ($index) = @_;
	$index--;

	return ( 
		q{<?xml version="1.0" encoding="ISO-8859-1"?>
<rss version="2" xmlns:perlmonks="http://perlmonks.org/index.pl?node_id=393035"><channel><ttl>60</ttl>
<title>newest nodes xml generator</title>
<link>http://perlmonks.org/index.pl?node_id=30175</link>
<docs>http://blogs.law.harvard.edu/tech/rss</docs>
<generator>PerlMonks Newest Nodes XML Generator</generator>
<perlmonks:foruser_id>456192</perlmonks:foruser_id>
<perlmonks:sitename>PerlMonks</perlmonks:sitename>
<perlmonks:gentimeGMT>2006-11-03 21:00:57</perlmonks:gentimeGMT>
<perlmonks:style>rss,clean</perlmonks:style>
<perlmonks:got_from>Thu Nov  2 16:00:57 2006</perlmonks:got_from>
<perlmonks:min_poll_seconds>30</perlmonks:min_poll_seconds>
<perlmonks:lastchecked>20061102160057</perlmonks:lastchecked>
<perlmonks:req_from>Thu Nov  2 16:00:57 2006</perlmonks:req_from>
<perlmonks:site>http://perlmonks.org/</perlmonks:site>
<perlmonks:foruser>BaldPenguin</perlmonks:foruser>
<item perlmonks:itemtype="node"><title>Question on qx</title>
<link>http://perlmonks.org/index.pl?node_id=582160</link>

<description>Revered Monks,

What is return value of qx ? I tried doing the following but I did not get any value for $status.

$status = qx/cat new1 &gt;new/;
print "value of status is $status \n";
...</description>
<category>perlquestion</category>
<pubDate>Fri, 03 Nov 2006 12:49:37 -0800</pubDate>
<guid>582160</guid>
<perlmonks:node_id>582160</perlmonks:node_id>
<perlmonks:author_user>501387</perlmonks:author_user>
<perlmonks:createtime>2006-11-03 15:49:37</perlmonks:createtime>
<perlmonks:authortitle>narashima</perlmonks:authortitle>
</item>
</channel>
</rss>},
		q{<?xml version="1.0" encoding="ISO-8859-1"?>
<rss version="2" xmlns:perlmonks="http://perlmonks.org/index.pl?node_id=393035"><channel><ttl>60</ttl>
<title>newest nodes xml generator</title>
<link>http://perlmonks.org/index.pl?node_id=30175</link>
<docs>http://blogs.law.harvard.edu/tech/rss</docs>
<generator>PerlMonks Newest Nodes XML Generator</generator>
<perlmonks:foruser_id>456192</perlmonks:foruser_id>
<perlmonks:sitename>PerlMonks</perlmonks:sitename>
<perlmonks:gentimeGMT>2006-11-03 21:00:57</perlmonks:gentimeGMT>
<perlmonks:style>rss,clean</perlmonks:style>
<perlmonks:got_from>Thu Nov  2 16:00:57 2006</perlmonks:got_from>
<perlmonks:min_poll_seconds>30</perlmonks:min_poll_seconds>
<perlmonks:lastchecked>20061102160057</perlmonks:lastchecked>
<perlmonks:req_from>Thu Nov  2 16:00:57 2006</perlmonks:req_from>
<perlmonks:site>http://perlmonks.org/</perlmonks:site>
<perlmonks:foruser>BaldPenguin</perlmonks:foruser>
<item perlmonks:itemtype="node"><title>Question on qx</title>
<link>http://perlmonks.org/index.pl?node_id=582160</link>

<description>Revered Monks,

What is return value of qx ? I tried doing the following but I did not get any value for $status.

$status = qx/cat new1 &gt;new/;
print "value of status is $status \n";
...</description>
<category>perlquestion</category>
<pubDate>Fri, 03 Nov 2006 12:49:37 -0800</pubDate>
<guid>582160</guid>
<perlmonks:node_id>582160</perlmonks:node_id>
<perlmonks:author_user>501387</perlmonks:author_user>
<perlmonks:createtime>2006-11-03 15:49:37</perlmonks:createtime>
</item>
</channel>
</rss>},
	)[$index];
}
