#!perl

use strict;
use warnings;

use Test::More tests => 2;
use Text::WikiFormat as => 'wikiformat';

my $wikitext =<<WIKI;

    * This should be a list.

    1. This should be an ordered list.

* This is like the default unordered list
* But not indented

    ! This is like the default unordered list
    ! But marked differently

WIKI

my %format_tags = ( blocks => { unordered => qr/\s*!\s*/ } );
 
my $htmltext = wikiformat( $wikitext, \%format_tags, {} );
like( $htmltext, qr!<li>But marked differently</li>!m,
	'redefining a list type works with use as' );

%format_tags = (
	indent => qr//,
	blocks => { 
		ordered         => qr/^\s*([\dA-Za-z]+)\.\s*/, 
		unordered       => qr/\s*\*\s*/
	},
	indented => { unordered => 0 },
); 

$htmltext = wikiformat( $wikitext, \%format_tags, {} );
like( $htmltext, qr!<li>But not indented!m,
	'redefining a list type to require no indent works with use as' );
