#!/usr/bin/perl
package Atom;
use lib '../lib';

use XML::Loy with => (
  prefix => 'atom',
  namespace => 'http://www.w3.org/2005/Atom',
  mime => 'application/atom+xml'
);

# Add id
sub add_id {
  my $self = shift;
  my $id   = shift;
  return unless $id;
  my $element = $self->add('id', $id);
  $element->parent->attr('xml:id' => $id);
  return $element;
};

package Fun;
use lib '../lib';

use XML::Loy with => (
  namespace => 'http://sojolicious.example/ns/fun',
  prefix => 'fun'
);

sub add_happy {
  my $self = shift;
  my $word = shift;

  my $cool = $self->add('-Cool');

  $cool->add('Happy',
	     {foo => 'bar'},
	     uc($word) . '!!! \o/ ' );
};


package Animal;
use lib '../lib';

use XML::Loy with => (
  namespace => 'http://sojolicious.example/ns/animal',
  prefix => 'anim'
);

package Nothing;
use XML::Loy 'hui';

package Nothing2;
use XML::Loy 'with';


package main;
use lib '../lib';

use Test::More tests => 58;
use Test::Warn;

use_ok('XML::Loy::Atom');

my $fun_ns  = 'http://sojolicious.example/ns/fun';
my $atom_ns = 'http://www.w3.org/2005/Atom';

ok(my $node = Fun->new('Fun'), 'Constructor');
ok(my $text = $node->add('Text', 'Hello World!'), 'Add element');

is($text->mime, 'application/xml', 'Mime type');
is($node->mime, 'application/xml', 'Mime type');

is(Fun->mime, 'application/xml', 'Mime class method');


is($node->at(':root')->namespace, $fun_ns, 'Namespace');
is($text->namespace, $fun_ns, 'Namespace');

ok(my $yeah = $node->add_happy('Yeah!'), 'Add yeah');

is($yeah->namespace, $fun_ns, 'Namespace');
is($node->at('Cool')->namespace, $fun_ns, 'Namespace');

ok($node = XML::Loy->new('object'), 'Constructor');

ok(!$node->at(':root')->namespace, 'Namespace');

warning_is { $node->add_happy('yeah') }
q{Can't locate "add_happy" in "XML::Loy"},
  'Warning';

ok($node->extension('Fun'), 'Add extension');
ok($yeah = $node->add_happy('Yeah!'), 'Add another yeah');

warning_is { $node->add_puppy('yeah') }
q{Can't locate "add_puppy" in "XML::Loy" with extension "Fun"},
  'Warning';

ok($node->extension('Animal'), 'Add extension');

warning_is { $node->add_puppy('yeah') }
q{Can't locate "add_puppy" in "XML::Loy" with extensions "Fun", "Animal"},
  'Warning';

is($yeah->namespace, $fun_ns, 'Namespace');
is($yeah->mime, 'application/xml', 'Mime type');
is($node->mime, 'application/xml', 'Mime type');

ok($text = $node->add('Text', 'Hello World!'), 'Add hello world');

ok(!$text->namespace, 'Namespace');

is(join(',', $text->extension), 'Fun,Animal', 'Extensions');
ok($text->extension('Atom'), 'Add Atom');
is(join(',', $text->extension), 'Fun,Animal,Atom', 'Extensions');

is($text->mime, 'application/xml', 'Mime type');

ok(my $id = $node->add_id('1138'), 'Add id');

is($id->namespace, $atom_ns, 'Namespace');

ok(!$node->at('Cool')->namespace, 'Namespace');

ok($node = Fun->new('Fun'), 'Get node');

ok($node->extension('Atom'), 'Add Atom 1');
is(join(',', $node->extension), 'Atom', 'Extensions');

$yeah = $node->add_happy('Yeah!');

ok($id = $node->add_id('1138'), 'Add id');

is($yeah->namespace, $fun_ns, 'Namespace');
is($node->at('Cool')->namespace, $fun_ns, 'Namespace');

is($id->namespace, $atom_ns, 'Namespace');

is($id->text, '1138', 'Content');


# New test
ok(my $xml = XML::Loy->new('entry'), 'Constructor');
ok($xml->extension('Fun', 'Atom'), 'Add 2 extensions');
ok($xml->extension('Fun', 'Atom'), 'Add  extensions');

ok($xml = Atom->new('entry'), 'Constructor');
ok($xml->add_id(45), 'Add id');

is($xml->mime, 'application/atom+xml', 'Check mime');


# Default extensions:
ok($xml = XML::Loy::Atom->new('feed'), 'Constructor');
ok($xml->extension('-Atom::Threading', -ActivityStreams), 'Extensions');
ok($xml->extension('XML::Loy::Atom::Threading', 'XML::Loy::ActivityStreams'), 'Extensions');

is($xml->at('feed')->attr('loy:ext'),
   'XML::Loy::Atom::Threading; XML::Loy::ActivityStreams',
   'Extensions');

ok(my $entry = $xml->entry(id => 'myentry'), 'New entry');
ok($entry->actor(name => 'Donald'), 'Add actor');
ok($entry->total(4), 'Add total');
is($entry->author->[0]->at('name')->text, 'Donald', 'Get name');
is($entry->actor->at('object-type')->text,
   'http://activitystrea.ms/schema/1.0/person', 'Is person');
is($entry->total, 4, 'total');
is($xml->at('feed')->attr('loy:ext'),
   'XML::Loy::Atom::Threading; XML::Loy::ActivityStreams',
   'Extensions');


# Delegate:
ok($node = XML::Loy->new, 'New document');

warning_is {
  $node->extension('Stupid', 'Atom');
}
q{There is no document to associate the extension with},
  'Warning';

__END__

$id = $node->add_id('1138');

  $yeah = $node->add_happy('Yeah!');

is($yeah->namespace, $fun_ns, 'Namespace');
is($node->at('Cool')->namespace, $fun_ns, 'Namespace');
is($id->namespace, $atom_ns, 'Namespace');
is($id->text, '1138', 'Content');


__END__

