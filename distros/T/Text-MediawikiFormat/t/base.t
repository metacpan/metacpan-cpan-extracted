#!perl

BEGIN { chdir 't' if -d 't' }

use strict;
use warnings;

use Test::More tests => 35;

my $module = 'Text::MediawikiFormat';
use_ok $module or exit;

can_ok $module, '_start_block';
my $text = <<END_WIKI;
= heading =

	* unordered item
	1. ordered item

	  some code

a normal paragraph

END_WIKI

sub fetchsub {
	return $module->can( $_[0] );
}

my $tags = \%Text::MediawikiFormat::tags;
local *Text::MediawikiFormat::tags = $tags;
my $opts = \%Text::MediawikiFormat::opts;
local *Text::MediawikiFormat::opts = $opts;

my $sb = fetchsub '_start_block';
my ($result) = $sb->( '= heading =', $tags );

ok $result->isa('Text::MediawikiFormat::Block::header'), '_start_block() should find headings'
	or diag "... it's a $result";

is $result->level(), 0, '... at the correct level';

($result) = $sb->( '** unordered item', $tags );

ok $result->isa('Text::MediawikiFormat::Block::unordered'), '_start_block() should find unordered lists'
	or diag "... it's a $result";
is $result->level(), 2, '... at the correct level';
is join( '', $result->text() ), 'unordered item', '... with the correct text';

($result) = $sb->( '## ordered item', $tags );

ok $result->isa('Text::MediawikiFormat::Block::ordered'), '_start_block() should find ordered lists'
	or diag "... it's a $result";
is $result->level(), 2, '... at the correct level';
is join( '', $result->text() ), 'ordered item', '... with the correct text';

($result) = $sb->( ' some code', $tags );

ok $result->isa('Text::MediawikiFormat::Block::code'), '_start_block() should find code' or diag "... it's a $result";
is $result->level(), 0, '... at the correct level';
is join( '', $result->text() ), "some code", '... with the correct text';

($result) = $sb->( 'paragraph', $tags );

ok $result->isa('Text::MediawikiFormat::Block::paragraph'), '_start_block() should find paragraph'
	or diag "... it's a $result";
is $result->level(), 0, '... at the correct level';
is join( '', $result->text() ), 'paragraph', '...with the correct text';

can_ok $module, '_nest_blocks';
my $nb     = fetchsub '_nest_blocks';
my @result = $nb->(
	[
		map { Text::MediawikiFormat::new_block(@$_) }[ 'code', text => 'a', level => 1 ],
		[ 'code', text => 'b', level => 1 ],
	]
);
is @result, 1, '_nest_blocks() should merge identical blocks together';
is_deeply $result[0]{text}, [qw(a b)], '...merging their text';

@result = $nb->(
	[
		map { Text::MediawikiFormat::new_block(@$_) }[ 'unordered', text => 'foo', level => 1 ],
		[ 'unordered', text => 'bar', level => 1 ],
	],
	$tags
);
is @result, 1, '... merging unordered blocks';
is_deeply $result[0]{text}, [qw(foo bar)], '...and their text';

@result = $nb->(
	[
		map { Text::MediawikiFormat::new_block(@$_) }[ 'ordered', text => 'foo', level => 2 ],
		[ 'ordered', text => 'bar', level => 3 ],
	],
	$tags
);
is @result, 2, '... not merging blocks at different levels';

can_ok $module, '_process_blocks';
my $pb     = fetchsub '_process_blocks';
my @opts   = ( tags => $tags, opts => $opts );
my @blocks = map { Text::MediawikiFormat::new_block( @$_, @opts ) }[
	'header',
	text  => [''],
	level => 0,
	args  => [ '==', 'my header' ]
	],
	[
	'end',
	text  => [''],
	level => 0,
	@opts
	],
	[
	'paragraph',
	text  => [qw(my lines of text)],
	args  => [],
	level => 0
	],
	[ 'end', text => [''], level => 0, @opts ],
	[
	'ordered',
	text => [
		qw(my ordered lines),
		Text::MediawikiFormat::new_block(
			'unordered',
			text  => [qw(my unordered lines)],
			level => 3,
			args  => [],
			@opts
		),
	],
	level => 2,
	args  => []
	];

# it's hard to fake these up; this may be a bad test
$blocks[2]{args}          = [ [],  [],  [] ];
$blocks[4]{args}          = [ [2], [3], [5] ];
$blocks[4]{text}[3]{args} = [ [],  [],  [] ];

@result = $pb->( \@blocks, $tags, $opts );

is @result, 1, '_process_blocks() should return processed text';
$result = $result[0];
like $result, qr!<h2>my header</h2>!,            '...marking header';
like $result, qr!<p>my[^<]+text</p>\n!s,         '...paragraph';
like $result, qr!<ol>\n<li>my</li>.+<li>lines!s, '...ordered list';
like $result, qr!<ul>\n<li>my</li>!m,            '...and unordered list';
like $result, qr!</li>\n</ul>\n</li>\n</ol>!,    '...nesting properly';

my $f = fetchsub('format');
my $fullresult = $f->( <<END_WIKI, $tags, { process_html => 0 } );
== my header ==

my
lines
of
text

# my
# ordered
# lines
#* my
#* unordered
#* lines
END_WIKI

is $fullresult, $result, 'format() should give same results';

$fullresult = $f->( <<END_WIKI, $tags, { process_html => 0 } );
= heading =

* aliases can expire
** use the Expires directive
** no messages sent after the expiration date
* aliases can be closed
** use the Closed directive
** messages allowed only from people on the list
* aliases can auto-add people
** use the Auto-add directive
** anyone in the Cc line is added to the alias
** they won't get duplicates
** makes "just reply to alias" easier

END_WIKI

like $fullresult, qr!expire<ul>!,       'nested list should start immediately';
like $fullresult, qr!date</li>\n</ul>!, '... ending after last nested item';

can_ok $module, '_check_blocks';

my @warnings;
local $SIG{__WARN__} = sub {
	push @warnings, shift;
};

my $cb      = \&Text::MediawikiFormat::_check_blocks;
my $newtags = {
	blocks     => { foo => 1, bar => 1, baz => 1 },
	blockorder => [qw(bar baz)],
};
$cb->($newtags);
my $warning = shift @warnings;
like $warning, qr/No order specified for blocks: foo\./, '_check_blocks() should warn if block is not ordered';

$newtags->{blockorder} = ['baz'];
$cb->($newtags);
$warning = shift @warnings;
ok $warning =~ /foo/ && $warning =~ /bar/, '... for all missing blocks'
	or diag $warning;
