#!perl

BEGIN { chdir 't' if -d 't' }

use strict;
use warnings;

use Test::More tests => 14;
use Test::NoWarnings;

use Text::MediawikiFormat as => 'wf', process_html => 0;

my $wikitext = <<WIKI;

* This should be a list.

# This should be an ordered list.

! This is like the default unordered list
! But marked differently

WIKI

my $htmltext = wf($wikitext);
like( $htmltext, qr!<li>This should be a list.</li>!m,          'unordered lists should be rendered correctly' );
like( $htmltext, qr!<li>This should be an ordered list.</li>!m, '...and ordered lists too' );

# Redefine all the list regexps to what they were to start with.
my %tags = (
	blocks => {
		ordered   => qr/^#\s*/,
		unordered => qr/^\*\s*/,
		code      => qr/^ /,
	},
);

$htmltext = wf( $wikitext, \%tags );
like(
	$htmltext,
	qr!<li>This should be a list.</li>!m,
	'unordered should remain okay when we redefine all list regexps'
);
like( $htmltext, qr!<li>This should be an ordered list.</li>!m, '... and so should ordered' );

# Redefine again, set one of them to something different.
%tags = (
	blocks => {
		ordered   => qr/^#\s*/,
		unordered => qr/^!\s*/,
		code      => qr/^ /,
	},
);

$htmltext = wf( $wikitext, \%tags );
like( $htmltext, qr!<li>But marked differently</li>!m,          'unordered should still work when redefined' );
like( $htmltext, qr!<li>This should be an ordered list.</li>!m, '...and ordered should be unaffected' );

# Now try redefining just one list type.
%tags = ( blocks => { unordered => qr/^!\s*/ }, );

$htmltext = wf( $wikitext, \%tags );
like(
	$htmltext,
	qr!<li>This is like the default unordered list</li>!m,
	'redefining just one list type should work for that type'
);
like( $htmltext, qr!<li>This should be an ordered list.</li>!m, '...and should not affect other types too' );

# now test overriding strong and emphasized tags
# don't use // to mark emphasized tags unless you /like/ this lookbehind
%tags = (
	strong_tag     => qr/\*(.+?)\*/,
	emphasized_tag => qr|(?<!<)/(.+?)/|,
);

$wikitext = 'this is *strong*, /emphasized/, and */emphasized strong/*';
$htmltext = wf( $wikitext, \%tags );

like( $htmltext, qr!<strong>strong</strong>!,          '... overriding strong tag' );
like( $htmltext, qr!<em>emphasized</em>!,              '... overriding emphasized tag' );
like( $htmltext, qr!<strong><em>em.+ng</em></strong>!, '... and both at once' );

# Test redefining just one list type after using import with a list definition.
package Bar;
Text::MediawikiFormat->import(
	as     => 'wf',
	blocks => {
		unordered => qr/^!\s*/
	},
	process_html => 0,
);

$htmltext = wf( "!1. Ordered list\n! Unordered list", { blocks => { ordered => qr/^\s*!([\d]+)\.\s*/ } }, {} );
::like( $htmltext, qr!<li>Ordered list</li>!m, 'redefining a single list type after import should work for that type' );
::like( $htmltext, qr!<li>Unordered list</li>!m, '...and also for a different type defined on import' );
