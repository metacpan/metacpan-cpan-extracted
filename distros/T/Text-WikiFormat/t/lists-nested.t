#!perl

use strict;
use warnings;

use Test::More tests => 6;

use_ok( 'Text::WikiFormat' ) or exit;
my $wikitext =<<END_HERE;
	* start of list
	* second line
		* indented list
	* now back to the first
END_HERE

my $htmltext = Text::WikiFormat::format( $wikitext );
like( $htmltext, qr|second line<ul>.*?<li>indented|s,
	'nested lists should start correctly' );
like( $htmltext, qr|indented list.*?</li>.*?</ul>|s,
	'... and end correctly' );

$wikitext =<<END_HERE;
	* 1
	* 2
		* 2.1
			* 2.1.1
	* 3

    * 4
        * 4.1
            * 4.1.1
            * 4.1.2
    * 5
END_HERE

$htmltext = Text::WikiFormat::format( $wikitext );

like( $htmltext,
	  qr|<ul>\s*
	     <li>1</li>\s*
	     <li>2<ul>\s*
	     <li>2\.1<ul>\s*
	     <li>2\.1\.1</li>\s*
	     </ul>\s*
	     </li>\s*
	     </ul>\s*
	     </li>\s*
	     <li>3</li>\s*
	     </ul>\s*
	     <ul>\s*
	     <li>4<ul>\s*
	     <li>4\.1<ul>\s*
	     <li>4\.1\.1</li>\s*
	     <li>4\.1\.2</li>\s*
	     </ul>\s*
	     </li>\s*
	     </ul>\s*
	     </li>\s*
	     <li>5</li>\s*
	     </ul>|sx,
	  'nesting should be correct for multiple levels' );
like( $htmltext, qr|<li>4<|s,
	'spaces should work instead of tabs' );
like( $htmltext,
	  qr|<li>4<ul>\s*<li>4.1<ul>\s*<li>4.1.1</li>\s*<li>4.1.2</li>\s*</ul>
	  \s*</li>|sx,
	  'nesting should be correct for spaces too' );
