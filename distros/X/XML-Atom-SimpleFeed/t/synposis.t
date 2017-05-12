use strict;
use warnings;

use XML::Atom::SimpleFeed;
use Test::More 0.88; # for done_testing
BEGIN { eval { require Test::LongString; Test::LongString->import; 1 } or *is_string = \&is; }

my $g = XML::Atom::SimpleFeed::DEFAULT_GENERATOR;

my $feed = XML::Atom::SimpleFeed->new(
	title   => 'Example Feed',
	link    => 'http://example.org/',
	link    => { rel => 'self', href => 'http://example.org/atom', },
	updated => '2003-12-13T18:30:02Z',
	author  => 'John Doe',
	id      => 'urn:uuid:60a76c80-d399-11d9-b93C-0003939e0af6',
);

$feed->add_entry(
	title     => 'Atom-Powered Robots Run Amok',
	link      => 'http://example.org/2003/12/13/atom03',
	id        => 'urn:uuid:1225c695-cfb8-4ebb-aaaa-80da344efa6a',
	summary   => 'Some text.',
	updated   => '2003-12-13T18:30:02Z',
	category  => 'Atom',
	category  => 'Miscellaneous',
);

is_string $feed->as_string."\n", << "", 'synopsis code produces expected output';
<?xml version="1.0" encoding="us-ascii"?>
<feed xmlns="http://www.w3.org/2005/Atom"><title>Example Feed</title><link href="http://example.org/"/><link href="http://example.org/atom" rel="self"/><updated>2003-12-13T18:30:02Z</updated><author><name>John Doe</name></author><id>urn:uuid:60a76c80-d399-11d9-b93C-0003939e0af6</id><generator uri="$g->{'uri'}" version="$g->{'version'}">$g->{'name'}</generator><entry><title>Atom-Powered Robots Run Amok</title><link href="http://example.org/2003/12/13/atom03"/><id>urn:uuid:1225c695-cfb8-4ebb-aaaa-80da344efa6a</id><summary>Some text.</summary><updated>2003-12-13T18:30:02Z</updated><category term="Atom"/><category term="Miscellaneous"/></entry></feed>

done_testing;
