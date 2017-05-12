#!perl

BEGIN { chdir 't' if -d 't' }

use strict;
use warnings;

# for testing 'rootdir' in links
my %constants = ( rootdir => 'rootdir', );

local *Text::MediawikiFormat::getCurrentStatic;
*Text::MediawikiFormat::getCurrentStatic = sub {
	return \%constants;
};

use Test::More tests => 34;
use Test::NoWarnings;

use_ok 'Text::MediawikiFormat';

my $wikitext = <<WIKI;
'''hello'''
''hi''
-----
woo
-----
LinkMeSomewhere
[[LinkMeElsewhere|BYE]]

* unordered one
* unordered two

# ordered one
# ordered two

 code one
 code two

WIKI

ok %Text::MediawikiFormat::tags, '%tags should be available from Text::MediawikiFormat';
my %tags = %Text::MediawikiFormat::tags;

ok %Text::MediawikiFormat::opts, '%opts should be available from Text::MediawikiFormat';
my %opts = (
	%Text::MediawikiFormat::opts,
	prefix         => 'rootdir/wiki.pl?page=',
	implicit_links => 1,
	extended       => 0,
	process_html   => 0,
);

my $htmltext = Text::MediawikiFormat::format_line( $wikitext, \%tags, \%opts );

like $htmltext, qr!\[<a href='rootdir/wiki\.pl\?page=LinkMeElsewhere'>!,
	'format_line () should link StudlyCaps where found)';
like $htmltext, qr!<strong>hello</strong>!, 'three ticks should mark strong';
like $htmltext, qr!<em>hi</em>!,            'two ticks should mark emphasized';
like $htmltext, qr!LinkMeSomewhere</a>\n!m, 'should catch StudlyCaps';
like $htmltext, qr!\[\[!,                   'should not handle extended links without flag';

$opts{extended} = 1;
$htmltext = Text::MediawikiFormat::format_line( $wikitext, \%tags, \%opts );
like $htmltext, qr!^<a href='rootdir/wiki\.pl\?page=LinkMeElsewhere'>BYE!m, 'should handle extended links with flag';

$htmltext = Text::MediawikiFormat::format( $wikitext, {}, { process_html => 0 } );
like $htmltext, qr!<strong>hello</strong>!, 'three ticks should mark strong';
like $htmltext, qr!<em>hi</em>!,            'two ticks should mark emphasized';

is scalar @{ $tags{ordered} }, 4, '...default ordered entry should have four items';
is join( '', map { ref $_ } @{ $tags{ordered} } ), '', '...and should have no subrefs';

# make sure this starts a paragraph (buglet)
$htmltext = Text::MediawikiFormat::format(
	"nothing to see here\nmoveAlong\n",
	{},
	{
		prefix       => 'foo=',
		process_html => 0
	}
);
like $htmltext, qr!^<p>nothing!, '...should start new text with paragraph';

# another buglet had the wrong tag pairs when ending a list
my $wikiexample = <<WIKIEXAMPLE;
I am modifying this because ItIsFun.  There is:
# MuchJoy
# MuchFun
# MuchToDo

Here is a paragraph.
There are newlines in my paragraph.

Here is another paragraph.

 here is some code that should have ''emphatic text''
 how amusing

WIKIEXAMPLE

$htmltext = Text::MediawikiFormat::format(
	$wikiexample,
	{},
	{
		prefix       => 'foo=',
		process_html => 0
	}
);

like $htmltext, qr!^<p>I am modifying this!,   '... should use correct tags when ending lists';
like $htmltext, qr!<p>Here is a paragraph.\n!, '...should add no newline before paragraph, but at newline in paragraph';
like $htmltext,   qr!<p>Here is another paragraph.</p>!, '... should add no newline at end of paragraph';
like $htmltext,   qr|<em>emphatic text</em>|,            '...should sub markup in code sections';
unlike $htmltext, qr!<(\w+)></\1>!,                      '...but should not create empty lists';

$wikitext = <<WIKI;
[escape spaces in links]

WIKI

%opts = (
	prefix       => 'rootdir/wiki.pl?page=',
	process_html => 0,
);

$htmltext = Text::MediawikiFormat::format( $wikitext, {}, \%opts );
like $htmltext, qr!<a href='escape'!m,    '...should extended absolute links on spaces';
like $htmltext, qr!spaces in links</a>!m, '...should leave spaces alone in titles of extended links';

$wikitext = <<'WIKI';
= heading =
== sub heading ==

some text

=== sub sub heading ===

more text

WIKI

$htmltext = Text::MediawikiFormat::format( $wikitext, \%tags, \%opts );
like $htmltext, qr!<h1>heading</h1>!,     'headings should be marked';
like $htmltext, qr!<h2>sub heading</h2>!, '... and numbered appropriately';

# test overridable tags

ok !UNIVERSAL::can( 'main', 'wikiformat' ), 'Module should import nothing by default';

can_ok 'Text::MediawikiFormat', 'import';

SKIP: {
	# process_html defaults to 1, so we can't test the single-argument version
	# of the importer without the HTML modules.
	eval { require HTML::Parser; require HTML::Tagset; };
	skip "HTML::Parser or HTML::Tagset not installed", 1 if $@;

	# given an argument, export wikiformat() somehow
	package Foo;

	Text::MediawikiFormat->import('wikiformat');
	::can_ok 'Foo', 'wikiformat';
}

package Bar;
Text::MediawikiFormat->import(
	as           => 'wf',
	prefix       => 'foo',
	tag          => 'bar',
	process_html => 0
);
::can_ok 'Bar', 'wf';
::isnt \&wf, \&Text::MediawikiFormat::format, '...and should be a wrapper around format()';

my @args;
local *Text::MediawikiFormat::_format;
*Text::MediawikiFormat::_format = sub {
	@args = @_;
};

wf();
::is $args[1]{prefix}, 'foo', 'imported sub should pass through default option';
::is $args[0]{tag},    'bar', '... and default tag';

wf( 'text', { tag2 => 1 }, { prefix => 'baz' } );
::is $args[2], 'text', '...passing through text unharmed';
::is $args[3]{tag2},   1,     '...along with new tags';
::is $args[4]{prefix}, 'baz', '...overriding default args as needed';

1;
