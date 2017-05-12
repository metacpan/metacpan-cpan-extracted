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
  namespace => 'http://sojolicio.us/ns/fun',
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
  namespace => 'http://sojolicio.us/ns/animal',
  prefix => 'anim'
);

package main;
use lib '../lib';

use Test::More tests => 12;
use Test::Warn;

ok(my $atom = Atom->new('feed'), 'New atom');
ok(my $entry = $atom->add('entry'), 'Entry');
ok($entry->add_id(5), 'Add id');

ok(my $fun = $atom->as('Fun'), 'Convert to new Object');

ok($fun->add_happy('Yeah'), 'Add happy');

ok(my $animal = $fun->as('Animal', 'Atom'), 'Convert to new Object');

warning_is { $animal->add_happy('yeah') }
q{Can't locate "add_happy" in "Animal" with extension "Atom"},
  'Warning';

ok($animal->add_id('6'), 'Add happy');

is($animal->at('entry id')->text, 5, 'Correct id');

my $xml = XML::Loy->new('<XRD><Subject>akron</Subject></XRD>');

warning_is { $xml->alias('acct:akron@sojolicio.us') }
q{Can't locate "alias" in "XML::Loy"},
  'Warning';

my $xrd = $xml->as(-XRD, -HostMeta);

ok($xrd->alias('acct:akron@sojolicio.us'), 'Set alias');

my ($alias) = $xrd->alias;

is($alias, 'acct:akron@sojolicio.us', 'Alias is correct');
