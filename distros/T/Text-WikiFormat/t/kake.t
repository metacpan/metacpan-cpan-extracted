#!perl

use strict;
use warnings;

use Test::More tests => 7;

use Text::WikiFormat as => 'wikiformat';

my $wikitext = "
WikiTest

code: foo bar baz

";

my %format_tags = (
    indent => "",  # same problem if I put qr// here
    blocks => { code => qr/^code: / },
	indented => { code => 0 },
);

my $cooked = wikiformat($wikitext, \%format_tags, {} );
like( $cooked, qr|<code>foo bar baz\n</code>|,
	'unindented code markers should still work' );

$wikitext = <<WIKI;

* foo
** bar

WIKI

%format_tags = (
	indent   => qr/^(?:\t+|\s{4,}|\*?(?=\*+))/,
	blocks   => { unordered => qr/^\s*\*+\s*/ },
	nests    => { unordered => 1 },
);

$cooked = wikiformat($wikitext, \%format_tags );

like( $cooked, qr/<li>foo/,               'first level of unordered list' );
like( $cooked, qr/<ul>.+?<li>bar<\/li>/s, 'second level of unordered list' );

$wikitext = <<WIKI;

: boing

WIKI

my @blocks = @{ $Text::WikiFormat::tags{blockorder} };
%format_tags = (
	blocks     => { definition => qr/^:\s*/ },
	indented   => { definition => 0 },
	definition => [ "<dl>\n", "</dl>\n", "<dt><dd>", "\n" ],
	blockorder => [ 'definition', @blocks ],
);

$cooked = wikiformat($wikitext, \%format_tags );
like( $cooked, qr/<dt><dd>boing/, 'definition list works' );

$wikitext =<<WIKITEXT;

==== Welcome ====

==== LinkInAHeader ====

==== Header with an = in ====

WIKITEXT

$ENV{SHOW} = 1;
$cooked = wikiformat($wikitext, {}, { prefix => 'wiki.pl?' });

like( $cooked, qr|<h4>Welcome</h4>|, 'headings work' );
like( $cooked,
      qr|<h4><a href="wiki.pl\?LinkInAHeader">LinkInAHeader</a></h4>|,
      '... links work in headers' );
like( $cooked, qr|<h4>Header with an = in</h4>|, '...headers may contain =' );
