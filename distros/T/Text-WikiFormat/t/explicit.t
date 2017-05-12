#!perl

use strict;
use warnings;

use Test::More tests => 4;
use Text::WikiFormat;

my $wikitext =<<WIKI;

[Ordinary extended link]

[[Usemod extended link]]


WIKI

my $htmltext = Text::WikiFormat::format($wikitext, {}, { extended => 1 } );
like( $htmltext, qr!Ordinary extended link</a>!m,
	'extended links rendered correctly with default delimiters' );

# Redefine the delimiters to the same thing again.
my %tags = (
	extended_link_delimiters => [ '[', ']' ]
);

$htmltext = Text::WikiFormat::format($wikitext, \%tags, { extended => 1 } );
like( $htmltext, qr!Ordinary extended link</a>!m,
	'...and again when delimiter redefined to the same thing' );

# Redefine the delimiters to something different.
%tags = (
	extended_link_delimiters => [ '[[', ']]' ]
);

$htmltext = Text::WikiFormat::format($wikitext, \%tags, { extended => 1 } );
unlike( $htmltext, qr!Ordinary extended link</a>!m,
	'old-style extended links not recognised when delimiter overridden' );

like( $htmltext, qr!Usemod extended link</a>[^\]]!m,
	'...and new delimiters recognised' );
