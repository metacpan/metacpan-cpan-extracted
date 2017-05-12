#!/usr/bin/env perl

use Test::More tests => 26;

use strict;
use warnings;

use XML::TreePuller;

my $puller = new_puller();

ok(defined($puller->reader));
ok(ref($puller->reader) eq 'XML::LibXML::Reader');

my $element = $puller->next;
ok(defined($element));
ok(ref($element) eq 'XML::TreePuller::Element');

ok($element->name eq 'element');
ok($element->text eq 'barbiddlemore biddle');

ok(ref($element->attribute) eq 'HASH');
ok($element->attribute->{one} eq '1');
ok(defined($element->attribute('one')));
ok($element->attribute('one') eq '1');
ok(! defined($element->attribute('bogus')));

my @results = $element->get_elements('baz');
ok(scalar(@results) == 2);
foreach (@results) {
	ok(ref($_) eq 'XML::TreePuller::Element');
}
ok($results[0]->text eq 'biddle');
ok($results[1]->text eq 'more biddle');
ok($element->get_elements() != $element);

$element = $element->get_elements('baz');
ok(defined($element));
ok(ref($element) eq 'XML::TreePuller::Element');
ok($element->text eq 'biddle');


#double check the next() method for the array interface
#since it did not get tested above
$puller = new_puller();
undef($element);
my $path;


($path, $element) = $puller->next;
ok($path eq '/element');
ok(ref($element) eq 'XML::TreePuller::Element');
ok($element->name eq 'element');
ok(! defined($puller->next));

sub new_puller {
	my $puller = XML::TreePuller->new(location => 't/data/10-smallelement.xml');
	ok(defined($puller));
	
	$puller->iterate_at('/element' => 'subtree');
		
	return $puller;
}