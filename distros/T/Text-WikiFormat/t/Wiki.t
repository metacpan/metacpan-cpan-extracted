#!perl

use strict;
use warnings;

# for testing 'rootdir' in links
my %constants = (
	rootdir => 'rootdir',
);

local *Text::WikiFormat::getCurrentStatic;
*Text::WikiFormat::getCurrentStatic = sub {
	return \%constants;
};

use Test::More tests => 32;

use_ok( 'Text::WikiFormat' );

my $wikitext =<<WIKI;
'''hello'''
''hi''
-----
woo
-----
LinkMeSomewhere
[LinkMeElsewhere|BYE]

	* unordered one
	* unordered two

	1. ordered one
	2. ordered two

	code one
	code two

WIKI

ok( %Text::WikiFormat::tags, 
	'%tags should be available from Text::WikiFormat');

my %tags = %Text::WikiFormat::tags;
my %opts = ( 
	prefix => 'rootdir/wiki.pl?page=',
);

my $htmltext = Text::WikiFormat::format_line($wikitext, \%tags, \%opts);

like( $htmltext, qr!\[<a href="rootdir/wiki\.pl\?page=LinkMeElsewhere">!, 
	'format_line () should link StudlyCaps where found)' );
like( $htmltext, qr!<strong>hello</strong>!, 'three ticks should mark strong');
like( $htmltext, qr!<em>hi</em>!, 'two ticks should mark emphasized' );
like( $htmltext, qr!LinkMeSomewhere</a>\n!m, 'should catch StudlyCaps' );
like( $htmltext, qr!\[!, 'should not handle extended links without flag' );

$opts{extended} = 1;
$htmltext = Text::WikiFormat::format_line($wikitext, \%tags, \%opts);
like( $htmltext, qr!^<a href="rootdir/wiki\.pl\?page=LinkMeElsewhere">!m,
	'should handle extended links with flag' );

$htmltext = Text::WikiFormat::format($wikitext);
like( $htmltext, qr!<strong>hello</strong>!, 'three ticks should mark strong');
like( $htmltext, qr!<em>hi</em>!, 'two ticks should mark emphasized' );

is( scalar @{ $tags{ordered} }, 3, 
	'... default ordered entry should have three items' );
is( ref( $tags{ordered}->[2] ), 'CODE', '... and should have subref' );

# make sure this starts a paragraph (buglet)
$htmltext = Text::WikiFormat::format("nothing to see here\nmoveAlong\n", {}, 
	{ prefix => 'foo=' });
like( $htmltext, qr!^<p>nothing!, '... should start new text with paragraph' );

# another buglet had the wrong tag pairs when ending a list
my $wikiexample =<<WIKIEXAMPLE;
I am modifying this because ItIsFun.  There is:
    1. MuchJoy
    2. MuchFun
    3. MuchToDo

Here is a paragraph.
There are newlines in my paragraph.

Here is another paragraph.

	  here is some code that should have ''literal'' double single quotes
	  how amusing

WIKIEXAMPLE

$htmltext = Text::WikiFormat::format($wikiexample, {}, { prefix => 'foo=' });

like( $htmltext, qr!^<p>I am modifying this!,
	'... should use correct tags when ending lists' );
like( $htmltext, qr!<p>Here is a paragraph.<br />!,
	'... should add no newline before paragraph, but at newline in paragraph ');
like( $htmltext, qr!<p>Here is another paragraph.</p>!,
	'... should add no newline at end of paragraph' );
like( $htmltext, qr|''literal'' double single|,
	'... should treat code sections literally' );
unlike( $htmltext, qr!<(\w+)></\1>!, '... but should not create empty lists' );

$wikitext =<<WIKI;
[escape spaces in links]

WIKI

%opts = (
	prefix   => 'rootdir/wiki.pl?page=',
	extended => 1,
);

$htmltext = Text::WikiFormat::format($wikitext, {}, \%opts);
like( $htmltext,
	qr!<a href="rootdir/wiki\.pl\?page=escape%20spaces%20in%20links">!m,
	'... should escape spaces in extended links' );
like( $htmltext, qr!escape spaces in links</a>!m,
	'... should leave spaces alone in titles of extended links' );

$wikitext =<<'WIKI';
= heading =
== sub heading ==

some text

=== sub sub heading ===

more text

WIKI

$htmltext = Text::WikiFormat::format($wikitext, \%tags, \%opts);
like( $htmltext, qr!<h1>heading</h1>!,
	'headings should be marked' );
like( $htmltext, qr!<h2>sub heading</h2>!,
	'... and numbered appropriately' );

# test overridable tags

ok( ! main->can( 'wikiformat' ), 'Module should import nothing by default' );

can_ok( 'Text::WikiFormat', 'import' );

# given an argument, export wikiformat() somehow
package Foo;

Text::WikiFormat->import('wikiformat');
::can_ok( 'Foo', 'wikiformat' );

package Bar;
Text::WikiFormat->import( as => 'wf', prefix => 'foo', tag => 'bar' );
::can_ok( 'Bar', 'wf' );
::isnt( \&wf, \&Text::WikiFormat::format,
	'... and should be a wrapper around format()' );

my @args;
local *Text::WikiFormat::format;
*Text::WikiFormat::format = sub {
	@args = @_;
};

wf();
::is( $args[2]{prefix}, 'foo', 
	'imported sub should pass through default option' );
::is( $args[1]{tag}, 'bar', '... and default tag' );

wf('text', { tag2 => 1 }, { prefix => 'baz' });
::is( $args[0], 'text', '... passing through text unharmed' );
::is( $args[1]{tag2}, 1, '... along with new tags' );
::is( $args[2]{prefix}, 'baz', '... overriding default args as needed' );

1;
