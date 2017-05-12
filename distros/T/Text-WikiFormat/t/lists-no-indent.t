#!perl

use strict;
use warnings;

use Test::More tests => 7;
use Text::WikiFormat;

my $wikitext =<<WIKI;

    * This should be a list.

    1. This should be an ordered list.

* This is like the default unordered list
* But not indented

    ! This is like the default unordered list
    ! But marked differently

1. This is like the default ordered list
2. But not indented

WIKI

my $htmltext = Text::WikiFormat::format($wikitext);
like( $htmltext, qr!<li>This should be a list.</li>!m,
	'unordered lists should render correctly' );
like( $htmltext, qr!<li value="1">This should be an ordered list.</li>!m,
	'...ordered lists too' );

# Redefine all the list regexps to what they were to start with.
my %tags = (
	lists => {
		ordered   => qr/([\dA-Za-z]+)\.\s*/,
		unordered => qr/\*\s*/,
		code	  => qr//,
	},
);

$htmltext = Text::WikiFormat::format($wikitext, \%tags, {} );
like( $htmltext, qr!<li>This should be a list.</li>!m,
	'unordered should remain okay when we redefine all list regexps' );
like( $htmltext, qr!<li value="1">This should be an ordered list.</li>!m,
	'...ordered lists too' );

# Redefine again, set one of them to something different.
%tags = (
	blocks => {
		ordered   => qr/([\dA-Za-z]+)\.\s*/,
		unordered => qr/^\s*!\s*/,
		code	  => qr//,
	},
);

$htmltext = Text::WikiFormat::format($wikitext, \%tags, {} );
like( $htmltext, qr!<li>But marked differently</li>!m,
	'unordered should still work when redefined' );
like( $htmltext, qr!<li value="1">This should be an ordered list.</li>!m,
	'...ordered should be unaffected' );

# Now try it without requiring an indent.
%tags = (
	indent => qr/^\s*/,
    blocks => {
		ordered   => qr/^([\dA-Za-z]+)\.\s*/,
		unordered => qr/\*\s*/,
		code	  => qr/^ /,
	},
	indented => { unordered => 0 },
);

$htmltext = Text::WikiFormat::format($wikitext, \%tags, {} );
like( $htmltext, qr!<li>But not indented!m,
	'redefining a list type to require no indent should work' );
