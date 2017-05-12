#!perl

use strict;
use warnings;

use Test::More tests => 5;

use_ok( 'Text::WikiFormat' ) or exit;
ok( exists $Text::WikiFormat::tags{ blockorder },
	'TWF should have a blockorder entry in %tags' );

# isan ARRAY
isa_ok( $Text::WikiFormat::tags{ blockorder }, 'ARRAY', '... and we hope it' );

like( join(' ', @{ $Text::WikiFormat::tags{ blockorder } }),
	qr/ordered.+ordered.+code/,
	'... and code should come after ordered and unordered' );

my $wikitext =<<END_HERE;
	* first list item
	* second list item
END_HERE

my $htmltext = Text::WikiFormat::format( $wikitext );

like( $htmltext, qr!<li>first list item!,
	'lists should be able to start on the first line of text' );
