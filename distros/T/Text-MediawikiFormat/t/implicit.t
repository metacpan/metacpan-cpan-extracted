#!perl

BEGIN { chdir 't' if -d 't' }

use strict;
use warnings;

use Test::More tests => 4;
use Test::NoWarnings;

use Text::MediawikiFormat
	as           => 'wf',
	prefix       => 'rootdir/wiki.pl?page=',
	process_html => 0;

my $wikitext = <<WIKI;
StudlyCaps

WIKI

my $htmltext = wf($wikitext);
unlike $htmltext, qr!<a href='rootdir/wiki\.pl\?page=StudlyCaps'>!m,
	'should create links from StudlyCaps if implicit_links is left alone';

$htmltext = wf( $wikitext, {}, { implicit_links => 0 } );
unlike( $htmltext, qr!<a href='rootdir/wiki\.pl\?page=StudlyCaps'>!m, '...and if implicit_links set to 0' );

$htmltext = wf( $wikitext, {}, { implicit_links => 1 } );
like( $htmltext, qr!<a href='rootdir/wiki\.pl\?page=StudlyCaps'>!m, '...and if implicit_links set to 0' );
