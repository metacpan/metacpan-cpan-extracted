#!/usr/bin/perl
use strict;
use warnings;

use lib ('lib', '../lib', '../../lib', '../../../lib');

use Mojo::ByteStream 'b';
use Test::Mojo;
use Mojolicious::Lite;

use Test::More tests => 182;

my $poco_ns  = 'http://www.w3.org/TR/2011/WD-contacts-api-20110616/';
my $xhtml_ns = 'http://www.w3.org/1999/xhtml';

use_ok('XML::Loy::Atom');

# new
my $atom = XML::Loy::Atom->new('feed');
is(ref($atom), 'XML::Loy::Atom', 'new 1');

# New Text
# text
my $text = $atom->new_text('Hello World!');
is($text->at('text')->text, 'Hello World!', 'Text: text1');
$text = $atom->new_text(text => 'Hello World!');
is($text->at('text')->text, 'Hello World!', 'Text: text2');
$text = $atom->new_text(type => 'text',
			content => 'Hello World!');
is($text->at('text')->text, 'Hello World!', 'Text: text3');

# xhtml
$text = $atom->new_text(type => 'xhtml',
			content => 'Hello World!');

is($text->text, '', 'Text: xhtml1');
is($text->all_text, 'Hello World!', 'Text: xhtml2');

is($text->at('div')->namespace, $xhtml_ns, 'Text: xhtml3');

$text = $atom->new_text('xhtml' => 'Hello <strong>World</strong>!');
is($text->at('text')->text, '', 'Text: xhtml4');
is($text->at('text')->all_text, 'Hello World!', 'Text: xhtml5');
is($text->at('div')->namespace, $xhtml_ns, 'Text: xhtml6');

# html
$text = $atom->new_text(type => 'html',
			content => 'Hello <strong>World</strong>!');
is($text->at('text')->text,
   'Hello <strong>World</strong>!',
   'Text: html1'
    );
$text = $atom->new_text('html' => 'Hello <strong>World</strong>!');
is($text->at('text')->text,
   'Hello <strong>World</strong>!',
   'Text: html2'
    );

# New Person
my $person = $atom->new_person(name => 'Bender',
			       uri => 'http://sojolicious.example/bender');
is($person->at('name')->text, 'Bender', 'Person1');
is($person->at('uri')->text, 'http://sojolicious.example/bender', 'Person2');

# Add entry
ok(my $entry = $atom->entry(id => '#Test1'), 'Add entry with hash');
is($atom->at('entry > id')->text, '#Test1', 'Add entry 1');
$entry = $atom->entry(id => '#Test2');
is($atom->find('entry > id')->[0]->text, '#Test1', 'Add entry 2');
is($atom->find('entry > id')->[1]->text, '#Test2', 'Add entry 3');
is($atom->find('entry')->[0]->attr('xml:id'), '#Test1', 'Add entry 4');
is($atom->find('entry')->[1]->attr('xml:id'), '#Test2', 'Add entry 5');

# Add entry without id
ok($entry = $atom->entry(summary => 'Just fun'), 'Add entry without id');
ok($entry->add(id => '#Test3'), 'Add new entry');

is($atom->entry('#Test1')->at('id')->text, '#Test1', 'Get entry');
is($atom->entry('#Test2')->at('id')->text, '#Test2', 'Get entry');
is($atom->entry('#Test3')->at('id')->text, '#Test3', 'Get entry');
is($atom->entry('#Test3')->at('summary')->text, 'Just fun', 'Get entry');

# Add content
$entry = $atom->at('entry');

ok($entry->content('Test content'), 'Add content');

is($atom->at('entry content')->text,
   'Test content',
   'Add content 1');

ok($entry->content('html' => '<p>Test content'), 'New content add');

is($atom->at('entry content[type=html]')->text,
   '<p>Test content',
   'Add content 2');

ok($entry->content('xhtml' => '<p>Test content</p>'), 'New content add');
is($atom->at('entry content[type="xhtml"]')->text,
   '',
   'Add content 3');
is($atom->at('entry content[type="xhtml"]')->all_text,
   'Test content',
   'Add content 4');
is($atom->at('entry content[type="xhtml"] div')->namespace,
   'http://www.w3.org/1999/xhtml',
   'Add content 5');

is($entry->content->all_text, 'Test content', 'Content');

ok($entry->content('html' => '<p>Test content 2'), 'New content add');

is($entry->content->all_text, '<p>Test content 2', 'Content');

$atom->find('entry')
    ->[1]->content(type    => 'movie',
		   content => b('Test')->b64_encode);
like($atom->at('entry content[type="movie"]')->text,
    qr!\s*VGVzdA==\s*!,
    'Add content 6');

# Add author
$atom->author(name => 'Fry');
is($atom->at('feed > author > name')->text,
   'Fry',
   'Add author 1');
$entry = $atom->at('entry');
$entry->author($person);
is($atom->at('feed > entry > author > name')->text,
   'Bender',
    'Add author 2');
is($atom->at('feed > entry > author > uri')->text,
   'http://sojolicious.example/bender',
    'Add author 3');

ok($atom->author(name => 'Leela'), 'Add another author');
is($atom->author->[0]->at('name')->text, 'Fry', 'Get first author');
is($atom->author->[1]->at('name')->text, 'Leela', 'Get second author');
is($entry->author->[0]->at('name')->text, 'Bender', 'Get first author');

# Add category
$entry->category('world');
is($entry->at('category')->attr('term'),
   'world',
   'Add category 1');
ok($entry->at('category[term]'),
   'Add category 2');

ok($entry->category(label => 'yeah', term => 'people'),
   'Add another category');

is($entry->category->[0], 'world', 'Get first category');
is($entry->category->[1], 'people', 'Get second category');
ok(!$entry->category->[2], 'No third category');

# Add contributor
$atom->contributor(name => 'Leela');
is($atom->at('feed > contributor > name')->text,
   'Leela',
   'Add contributor 1');
$entry = $atom->find('entry')->[1];
$entry->contributor($person);
is($atom->at('feed > entry > contributor > name')->text,
   'Bender',
    'Add contributor 2');
is($atom->at('feed > entry > contributor > uri')->text,
   'http://sojolicious.example/bender',
    'Add contributor 3');

ok($atom->contributor(name => 'Fry'), 'Add another author');
is($atom->contributor->[0]->at('name')->text, 'Leela', 'Get first contributor');
is($atom->contributor->[1]->at('name')->text, 'Fry', 'Get second contributor');
is($entry->contributor->[0]->at('name')->text, 'Bender', 'Get first contributor');

# Set generator
ok($atom->generator('Sojolicious'), 'Set Generator');
is($atom->at('generator')->text, 'Sojolicious', 'Add generator');
ok($atom->generator('Sojolicious 2'), 'Set Generator');
is($atom->at('generator')->text, 'Sojolicious 2', 'Add generator');
is($atom->generator, 'Sojolicious 2', 'Get generator');

ok(my $c = $atom->new_text('Fun'), 'New text');
ok(!$c->generator('Sojolicious'), 'New Generator fails');

# Set icon
$entry->icon('http://sojolicious.example/favicon.ico');
is($atom->at('icon')->text, 'http://sojolicious.example/favicon.ico',
   'Add icon');
$entry->icon('http://sojolicious.example/favicon2.ico');
is($atom->at('icon')->text, 'http://sojolicious.example/favicon2.ico',
   'Add icon');
ok(!$c->icon('http://sojolicious.example/favicon3.ico'), 'New Icon fails');


# Add id
ok($entry = $atom->entry, 'New entry');
ok($entry->id('Test2'), 'Set entry id');
ok($atom->id('Test3'), 'Set entry id');

is($entry->id, 'Test2', 'Get id');
is($atom->id, 'Test3', 'Get id');


# Add link
$entry->link(related => 'http://sojolicious.example/alternative');
is($entry->at('link')->text, '', 'Add link 1');
is($entry->at('link')->attr('href'),
   'http://sojolicious.example/alternative',
   'Add link 2');

is($entry->at('link')->attr('rel'), 'related', 'Add link 3');
$entry->link(
  rel => 'self',
  href => 'http://sojolicious.example/entry',
  title => 'Self-Link'
);

is($entry->at('link[title]')->attr('title'),
   'Self-Link',
   'Add link 4'
 );

is($entry->link('related')->[0]->attr('href'),
   'http://sojolicious.example/alternative',
   'related link'
 );


# Add logo
$entry->logo('http://sojolicious.example/logo.png');
is($atom->at('logo')->text, 'http://sojolicious.example/logo.png',
   'Add logo');
$entry->logo('http://sojolicious.example/logo2.png');
is($atom->at('logo')->text, 'http://sojolicious.example/logo2.png',
   'Add logo');
ok(!$c->logo('http://sojolicious.example/favicon3.png'), 'New logo fails');

my $date = '2011-07-30T16:30:00Z';

# Add published
ok($entry->published('2011-07-30T16:30:00Z'),
   'Set publish date 1');
is($entry->at('published')->text,
   '2011-07-30T16:30:00Z',
   'Add published 1');
ok($atom->at('entry')->published(1314721000), 'Set published date 2');
is($atom->at('entry published')->text,
   '2011-08-30T16:16:40Z',
   'Add published 2');
ok($atom->published(1314721000), 'Set published date 3');
is($entry->published->to_string,
   '2011-07-30T16:30:00Z',
   'Get publish date 1');
is($atom->published->to_string,
   '2011-08-30T16:16:40Z',
   'Get publish date 2');


# Add rights
ok($atom->rights('Creative Commons'), 'Set rights in feed');
is($atom->at('rights')->text,
   'Creative Commons',
   'Add rights 1');
$entry->rights('xhtml' => '<p>Creative Commons</p>');
is($entry->at('rights')->text,
   '',
   'Add rights 2');
is($entry->at('rights')->all_text,
   'Creative Commons',
   'Add rights 3');

is($entry->rights->all_text, 'Creative Commons', 'Get rights');


# Add source
ok(my $source = $entry->source(
  {'xml:base' => 'http://source.sojolicious.example/'}
), 'Add source');

ok($source->author(name => 'Zoidberg'), 'Add author');
is($source->attr('xml:base'), 'http://source.sojolicious.example/',
   'Check Source');

is($atom->at('source > author > name')->text,
   'Zoidberg',
   'Add source');

is($entry->source->author->[0]->at('name')->all_text,
   'Zoidberg',
   'Name');

is($entry->source->attr('xml:base'),
   'http://source.sojolicious.example/',
   'Check Source');


# Add subtitle
ok($entry = $atom->at('entry'), 'Entry');
ok(!$entry->subtitle('Test subtitle'), 'No subtitle in entry');
ok($atom->subtitle('Test subtitle'), 'Subtitle in feed');

is($atom->at('subtitle')->text,
   'Test subtitle',
   'Set subtitle 1');
is($atom->subtitle->all_text, 'Test subtitle', 'Set subtitle 2');
ok($atom->subtitle('Test new subtitle'), 'Set subtitle 3');
is($atom->subtitle->all_text, 'Test new subtitle', 'Set subtitle 4');

ok($atom->subtitle('html' => '<p>Test subtitle'), 'Set subtitle');
is($atom->at('subtitle[type="html"]')->text,
   '<p>Test subtitle',
   'Add subtitle 2');
ok($atom->subtitle('xhtml' => '<p>Test subtitle</p>'), 'Set subtitle 2 1/2');
is($atom->at('subtitle[type="xhtml"]')->text,
   '',
   'Add subtitle 3');
is($atom->at('subtitle[type="xhtml"]')->all_text,
   'Test subtitle',
   'Add subtitle 4');
is($atom->at('subtitle[type="xhtml"] div')->namespace,
   'http://www.w3.org/1999/xhtml',
   'Add subtitle 5');
ok($atom->subtitle(
  type => 'movie',
  content => b('Test')->b64_encode
), 'Set subtitle 5 1/2');
like($atom->at('subtitle[type="movie"]')->text,
   qr!\s*VGVzdA==\s*!,
   'Add subtitle 6');
ok(my $subtitle = $atom->new_text('Test subtitle 2'), 'New test subtitle 2');
ok($atom->subtitle($subtitle), 'Add subtitle 7');

is($atom->subtitle->all_text, 'Test subtitle 2', 'Subtitle test 7');


# Add summary
ok($entry = $atom->at('entry'), 'Get entry');
ok($entry->summary('Test summary'), 'Set Summary 1');;
is($atom->at('entry summary')->text,
   'Test summary',
   'Add summary 1');
ok($entry->summary('html' => '<p>Test summary'), 'Set summary 2');
is($entry->summary->all_text, '<p>Test summary', 'Get summary html 1');
is($atom->at('entry summary[type="html"]')->text,
   '<p>Test summary',
   'Add summary 2');
ok($entry->summary('xhtml' => '<p>Test summary</p>'), 'Set summary 3');;
is($entry->summary->all_text, 'Test summary', 'Get summary xhtml 2');
is($atom->at('entry summary[type="xhtml"]')->text,
   '',
   'Add summary 3');
is($atom->at('entry summary[type="xhtml"]')->all_text,
   'Test summary',
   'Add summary 4');
is($atom->at('entry summary[type="xhtml"] div')->namespace,
   'http://www.w3.org/1999/xhtml',
   'Add summary 5');
ok($atom->find('entry')
     ->[1]->summary(
       type => 'movie',
       content => b('Test')->b64_encode
     ), 'Set summary 6');
like($atom->at('entry summary[type="movie"]')->text,
    qr!\s*VGVzdA==\s*!,
    'Add summary 6');
my $encode = b('Test')->b64_encode->trim;
like($atom->find('entry')->[1]->summary->all_text,
   qr/$encode/, 'Get summary movie 3');
ok(my $summary = $atom->new_text('Test summary 2'), 'New text');
ok(!$atom->summary($summary), 'Add summary to feed fails');



# Add title
ok($entry = $atom->at('entry'), 'Get first entry');
ok($entry->title('Test title'), 'Set title 1');
is($atom->at('entry title')->text,
   'Test title',
   'Add title 1');
is($entry->title->all_text, 'Test title', 'Get title 1');
ok($entry->title('html' => '<p>Test title'), 'Set html title');
is($atom->at('entry title[type="html"]')->text,
   '<p>Test title',
   'Add title 2');
is($entry->title->all_text, '<p>Test title', 'Get title 2');
ok($entry->title('xhtml' => '<p>Test title</p>'), 'Set xhtml title');
is($atom->at('entry title[type="xhtml"]')->text,
   '',
   'Add title 3');
is($atom->at('entry title[type="xhtml"]')->all_text,
   'Test title',
   'Add title 4');
is($atom->at('entry title[type="xhtml"] div')->namespace,
   'http://www.w3.org/1999/xhtml',
   'Add title 5');
ok($atom->find('entry')
    ->[1]->title(
      type => 'movie',
      content => $encode
    ), 'Set title 5 1/2');
is($atom->find('entry')->[1]->title->all_text, $encode,
   'Check movie');
is($atom->at('entry title[type="movie"]')->text,
   'VGVzdA==',
   'Add title 6');
ok(my $title = $atom->new_text('Test title 2'), 'Set title');
ok($atom->title($title), 'Add title 7');
is($atom->title->text, 'Test title 2', 'New test title');


# Add updated
ok($entry = $atom->find('entry')->[1], 'Get second entry');
ok($entry->updated($date), 'Set updated to entry');
is($entry->at('updated')->text,
   '2011-07-30T16:30:00Z',
   'Add updated 1');
ok($atom->at('entry')->updated(1314721000),
   'Set updated to first entry');
is($atom->at('entry updated')->text,
   '2011-08-30T16:16:40Z',
   'Add updated 2');
is($entry->updated->epoch, '1312043400', 'Get updated epoch');
ok($atom->updated('1312043800'), 'Set updated epoch');
is($entry->updated->epoch, '1312043400', 'Get updated epoch');
is($atom->updated->epoch, '1312043800', 'Get updated epoch');



# Examples
$atom = XML::Loy::Atom->new('entry');
$entry = $atom->entry(id => '#467r57');
ok($entry->author(name   => 'Bender'), 'Set Author');
ok($entry->content(text  => "I am Bender!"), 'Set text content');
ok($entry->content(html  => "I am <strong>Bender</strong>!"), 'Set html text');
ok($entry->content(xhtml => "I am <strong>Bender</strong>!"), 'Set xhtml content');
ok(!$entry->content(movie => b("I am Bender!")->b64_encode), 'Set Content');
ok($entry->content(text  => "I am Bender!"), 'Set text content');

is($atom->at('entry > author > name')->text, 'Bender', 'Text');
is($atom->at('content[type]')->text,  'I am Bender!', 'Text');
$entry->content(html  => "I am <strong>Bender</strong>!");
is($atom->at('content[type="html"]')->text,  'I am <strong>Bender</strong>!', 'Text');
$entry->content(xhtml => "I am <strong>Bender</strong>!");
is($atom->at('content[type="xhtml"]')->text,  '', 'Text');
like($atom->at('content[type="xhtml"] div')->text,  qr/I am\s*!/, 'Text');
is($atom->at('content[type="xhtml"] div')->all_text,  'I am Bender!', 'Text');
$atom->content(type => 'movie', content => b("I am Bender!")->b64_encode);
like($atom->at('content[type="movie"]')->text, qr!\s*SSBhbSBCZW5kZXIh\s*!, 'Text');

$atom = XML::Loy::Atom->new(<<'ATOM');
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<feed xmlns="http://www.w3.org/2005/Atom">
  <entry>
    <id>#467r57</id>
    <author>
      <name>Bender</name>
    </author>
  </entry>
</feed>
ATOM

is($atom->at('entry > author > name')->text, 'Bender', 'Text');

$poco_ns = 'http://www.w3.org/TR/2011/WD-contacts-api-20110616/';

# Person constructs
$person = $atom->new_person('name' => 'Fry');
$person->namespace('poco' => $poco_ns);
$person->add('uri', 'http://sojolicious.example/fry');
$person->add('poco:birthday' => '1/1/1970');

is($person->at('person name')->text, 'Fry', 'Person-Name');
is($person->at('person uri')->text, 'http://sojolicious.example/fry', 'Person-URI');
is($person->at('person birthday')->text, '1/1/1970', 'Person-Poco-Birthday');
is($person->at('person birthday')->namespace, $poco_ns, 'Person-Poco-NS');

# Date consructs
$atom->updated(1313131313);
is($atom->at('updated')->text, '2011-08-12T06:41:53Z', 'Updated');

# Unicode!
$atom = XML::Loy::Atom->new('feed');
is(ref($atom), 'XML::Loy::Atom', 'new 1');

ok($atom->content('Halä'), 'Add unicode content');
is($atom->content->text, 'Halä', 'Get content');
