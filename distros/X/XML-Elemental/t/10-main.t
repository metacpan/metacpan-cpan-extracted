#!perl

BEGIN { chdir 't' if -d 't' }

use strict;
use warnings;

use constant E => 'XML::Elemental::Element';
use constant C => 'XML::Elemental::Characters';

use Test::More tests => 45;

#--- compiles?
map { use_ok($_) }
  qw( 
    XML::Elemental XML::Elemental::SAXHandler XML::Elemental::Node
    XML::Elemental::Document XML::Elemental::Element
    XML::Elemental::Characters XML::Elemental::Util
    XML::Parser::Style::Elemental 
  );

#--- makes sure constructors works.

# ok(ref(XML::Elemental::Document->new) eq 'Object::Destroyer', 'XML::Elemental::Document constructor');
map { ok(ref($_->new) eq $_, "$_ constructor") }
  qw( 
    XML::Elemental::SAXHandler XML::Elemental::Node XML::Elemental::Document
    XML::Elemental::Element XML::Elemental::Characters 
  );

#--- can get parser
my $p = XML::Elemental->parser;
ok($p, 'XML::Elemental parser');

#--- can parse file properly
open my $fh, 'test.xml';
my $doc = $p->parse_file($fh);
ok($doc, 'parse file return');
ok(ref $doc eq 'XML::Elemental::Document',
    'parse_file returns document object');

#--- root tests
my $root;
ok($root = $doc->contents->[0], 'find root element');
$doc->contents([$root]);
ok($root = $doc->contents->[0], 'set root element as ARRAY ref');
ok($root->name eq '{}foo', 'root element is foo');

#--- children test
my @children = @{$root->contents};
ok(@children, 'has children');
my $i = 1;
map { ok($_->parent eq $root, 'parent test ' . $i++) } @children;
ok(scalar @children == 7, 'children count correct');
my ($default) = grep { $_->name eq '{}quuux' }
  grep { ref($_) eq E } @children;
ok($default, 'default namespaced element');
my ($namespaced) = grep { $_->name eq '{http://www.example.com/}bar' }
  grep { ref($_) eq E } @children;
ok($namespaced, 'namespaced element');
ok($namespaced->text_content eq 'Some title', 'attribute value');
my ($inline) = grep { $_->name eq '{http://www.example.net/}fred' }
  grep { ref($_) eq E } @children;
ok($inline, 'inline namespaced element');
my %attrs      = %{$inline->attributes};
my $attr_count = scalar keys %attrs;
ok($attr_count == 3, 'attribute count');
my ($alt_default) = grep { $_->name eq '{http://www.example.net/}quux' }
  grep { ref($_) eq E } @{$inline->contents};
ok($alt_default, 'temporary default namespace test');
# should be blank though in http://www.example.net/ because attributes 
# inherit the namespace of its associated element if not defined.
my ($nsq_attr) = grep { $_ eq '{}key' } 
    keys %{$alt_default->attributes};
ok($nsq_attr,'namespace attribute inheritence');
ok($attrs{'{http://www.example.com/}bat'} == 1,'attribute value 2');

#--- character tests
my $c = $namespaced->contents->[0];
ok(ref($c) eq C, 'is characters');
ok($c->data && !ref($c->data), 'characters data is scalar');
my $str = $inline->text_content;
ok($str eq "\n    foo\n", 'text content returns proper character string');

#--- root test
$i = 1;    # reset
ok($doc eq $_->root, 'root test ' . $i++." $doc ".$_->root) for
  ($c, $alt_default, $inline, $namespaced, $default, $root);
