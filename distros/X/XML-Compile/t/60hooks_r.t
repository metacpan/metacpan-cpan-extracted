#!/usr/bin/env perl
# hooks in ::Translate::Reader

use warnings;
use strict;

use lib 'lib','t';
use TestTools;

use XML::Compile::Schema;
use XML::Compile::Tester;

use Test::More tests => 45;

set_compile_defaults
    elements_qualified => 'NONE';

my $schema   = XML::Compile::Schema->new( <<__SCHEMA__ );
<schema targetNamespace="$TestNS"
        xmlns="$SchemaNS"
        xmlns:me="$TestNS">

<element name="test1" id="top">
  <complexType>
    <sequence>
      <element name="byType" type="string"         />
      <element name="byId"   type="int" id="my_id" minOccurs="0" />
      <element name="byPath" type="int"            />
    </sequence>
  </complexType>
</element>

<element name="test2" id="top2">
  <complexType>
    <attribute name="attr1" type="int" />
    <attribute name="attr2" type="int" />
  </complexType>
</element>

</schema>
__SCHEMA__

ok(defined $schema);

my $xml1 = <<__XML;
<test1>
  <byType>aap</byType>
  <byId>2</byId>
  <byPath>3</byPath>
</test1>
__XML

# test without hooks

my %f1 = (byType => 'aap', byId => 2, byPath => 3);
test_rw($schema, test1 => $xml1, \%f1);

# try all selectors and hook types

my (@out, @out2);
my $r2 = reader_create
 ( $schema, "combined hook" => "{$TestNS}test1"
 , hook => { type   => 'string'
           , id     => 'my_id'
           , path   => qr/byPath/
           , before => sub { push @out,  $_[1]; $_[0] }
           , after  => sub { push @out2, $_[2]; $_[1] }
           }
 );

my $h2 = $r2->($xml1);
ok(defined $h2, 'returned hash');
isa_ok($h2, 'HASH');

cmp_ok(scalar @out,  '==', 3, '3 objects logged before');
cmp_ok(scalar @out2, '==', 3, '3 objects logged after');

# test predefined and multiple "after"s

my $output;
open BUF, '>', \$output;
my $oldout = select BUF;

my $r3 = reader_create
 ( $schema, "after PATH and NODE" => "{$TestNS}test1"
 , hook => { id    => 'my_id'
           , after => [ qw/PRINT_PATH XML_NODE/ ]
           }
 );
my $h3 = $r3->($xml1);
ok(defined $h3, 'multiple after predefined');

select $oldout;
close BUF;

#use Data::Dumper;
#warn Dumper $h3;
like($output, qr[\}test1/byId\n$], 'PRINT_PATH');
is(ref($h3->{byId}), 'HASH', 'simpleType expanded');
ok(exists $h3->{byId}{_});
cmp_ok($h3->{byId}{_}, '==', 2);

ok(exists $h3->{byId}{_XML_NODE});
my $node = $h3->{byId}{_XML_NODE};
isa_ok($node, 'XML::LibXML::Element');
compare_xml($node, '<byId>2</byId>');

# test skip

my $r4 = reader_create
 ( $schema, "replace SKIP" => "{$TestNS}test1"
 , hook => { id      => 'my_id'
           , replace => 'SKIP'
           }
 );

my $h4 = $r4->($xml1);
ok(defined $h4, 'test skip');
cmp_ok(scalar keys %$h4, '==', 3);
ok(defined $h4->{byType});
ok(defined $h4->{byPath});
is($h4->{byId}, 'SKIPPED');

# test node order discovery

my $xml2 = <<__XML;
<test2 attr1="5" attr2="6" />
__XML

my $r5 = reader_create
 ( $schema, "read ORDER" => "{$TestNS}test2"
 , hook => { id    => 'top2'
           , after => [ qw/ELEMENT_ORDER ATTRIBUTE_ORDER/ ]
           }
 );
my $h5 = $r5->($xml2);

ok(defined $h5, "node order");
ok(exists $h5->{_ELEMENT_ORDER});
my $order = $h5->{_ELEMENT_ORDER}; 
is(ref $order, 'ARRAY');
cmp_ok(scalar @$order, '==', 0, "no elements");

ok(exists $h5->{_ATTRIBUTE_ORDER});
$order = $h5->{_ATTRIBUTE_ORDER}; 
is(ref $order, 'ARRAY');
is_deeply($order, [ qw/attr1 attr2/ ]);

# test element order

my $r6 = reader_create
 ( $schema, "element order" => "{$TestNS}test1"
 , hook => { id    => 'top'
           , after => [ qw/ELEMENT_ORDER ATTRIBUTE_ORDER/ ]
           }
 );
my $h6 = $r6->($xml1);

ok(defined $h6, "node order");
ok(exists $h6->{_ELEMENT_ORDER});
$order = $h6->{_ELEMENT_ORDER}; 
is(ref $order, 'ARRAY');
is_deeply($order, [ qw/byType byId byPath/ ]);

ok(exists $h6->{_ATTRIBUTE_ORDER});
$order = $h6->{_ATTRIBUTE_ORDER}; 
is(ref $order, 'ARRAY');
cmp_ok(scalar @$order, '==', 0, "no attributes");

