#!/usr/bin/perl -w

# A skeleton Atom document with extensions, to show different
#  behaviour of namespaces and prefixes

use strict;

use XML::Writer;

my $ATOM = 'http://www.w3.org/2005/Atom';
my $EXT = 'http://www.example.com/feed-extension';
my $EXT2 = 'http://www.example.com/feed-extension-2';
my $EXT3 = 'http://www.example.com/feed-extension-3';

my $w = XML::Writer->new(
	NAMESPACES => 1,
	DATA_MODE => 1,

	# Define prefixes for most of the namespaces
	PREFIX_MAP => {
		$ATOM => '',
		$EXT => 'ext',
		$EXT2 => 'ext2'
	},

	# Force a declaration for the first extension on the root element
	FORCED_NS_DECLS => [$EXT]
);


$w->comment(' An Atom feed with namespace declarations ');

$w->startTag([$ATOM, 'feed']);

# The root element will include a declaration for its own namespace
#  and the contents of FORCED_NS_DECLS
$w->dataElement([$ATOM, 'title'], "Feed Title");

# This namespace has already been declared on the root as the default
$w->dataElement([$EXT, 'example'], "true");

# This namespace had its name defined but the declaration hasn't appeared yet.
#  It will be included on demand, on this element.
$w->dataElement([$EXT2, 'definitely-an-example'], "true");

# This namespace has no prefix defined - an artificial prefix will be
#  used (something like __NS1)
$w->dataElement([$EXT3, 'most-definitely-an-example'], "true");

$w->endTag([$ATOM, 'feed']);

$w->end();
