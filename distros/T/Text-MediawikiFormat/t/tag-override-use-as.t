#!perl

BEGIN { chdir 't' if -d 't' }

use strict;
use warnings;

use Test::More tests => 3;
use Test::NoWarnings;

use Text::MediawikiFormat as => 'wf', process_html => 0;

my $wikitext = <<WIKI;

* This should be a list.

# This should be an ordered list.

** This is like the default unordered list
** But not indented

! This is like the default unordered list
! But marked differently

WIKI

my %format_tags = ( blocks => { unordered => qr/^!\s*/ } );

my $htmltext = wf( $wikitext, \%format_tags );
like( $htmltext, qr!<li>But marked differently</li>!m, 'redefining a list type works with use as' );

%format_tags = (
	indent => qr//,
	blocks => {
		ordered   => qr/^#\s*/,
		unordered => qr/^\*\s*/
	},
	indented => { unordered => 0 },
);

$htmltext = wf( $wikitext, \%format_tags );
like( $htmltext, qr!<li>\* But not indented!m, 'redefining a list type to require no indent works with use as' );
