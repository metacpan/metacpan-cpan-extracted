#!/usr/bin/env perl
# convert XML into objects and back

use warnings;
use strict;

use lib 'lib','t';
use TestTools;

use XML::Compile::Schema;
use XML::Compile::Tester;
use XML::Compile::Util qw/pack_type/;
use Data::Dumper;

use Test::More tests => 65;

set_compile_defaults
    elements_qualified => 'NONE';

my $schema   = XML::Compile::Schema->new( <<__SCHEMA__ );
<schema targetNamespace="$TestNS"
        xmlns="$SchemaNS"
        xmlns:me="$TestNS">

<element name="test1" type="me:test1" />
<simpleType name="test1">
  <restriction base="string"/>
</simpleType>

<element name="test2" type="me:test2" />
<complexType name="test2">
  <sequence>
    <element name="e2" type="string" />
  </sequence>
</complexType>
</schema>
__SCHEMA__

my $doc = XML::LibXML::Document->new('1.0', 'UTF-8');
ok(defined $doc, 'created document');

#
# Simple checks for "after" hook in reader, and "before" hook in writer
# we will use hooks, so be sure it works correctly.
#

my @out;
my $t1 = "{$TestNS}test1";
$schema->addHook(type => $t1, after => sub {@out = @_; $_[1]});

# reader

my $r1 = create_reader $schema, 'after hook' => $t1;
isa_ok($r1, 'CODE', 'after read');
my $h1 = $r1->('<test1>one</test1>');
is($h1, 'one', 'reader works');

cmp_ok(scalar @out, '==', 4, 'hook called with 4 params');
isa_ok($out[0], 'XML::LibXML::Node', 'got node');
is($out[1], 'one', 'parsed data');

# writer

@out = ();
my $w1 = create_writer $schema, 'after hook' => $t1;
isa_ok($w1, 'CODE', 'after read');
my $w1h = $w1->($doc, 'two');
isa_ok($w1h, 'XML::LibXML::Element', 'writer works');

cmp_ok(scalar @out, '==', 5, 'hook called with 5 params');
is($out[0], $doc, 'document');
isa_ok($out[1], 'XML::LibXML::Element', 'generated node');
is($out[2], $t1, 'type');
is($out[3], 'two', 'data');

###
##### now the real thing
###

#
# test typemap reader with code
#

my $type2 = pack_type $TestNS, 'test2';

@out = ();
my $r2 = create_reader $schema, "typemap code" => $type2
  , typemap => {$type2 => sub {@out = @_; $_[1]}};

ok(defined $r2, 'typemap reader from code');
my $h2 = $r2->('<test2><e2>bbb</e2></test2>');
cmp_ok(scalar(@out), '==', 3, 'reader with CODE');
is($out[0], 'READER');
is_deeply($out[1], {e2 => 'bbb'});
is($out[2], $type2);
isa_ok($h2, 'HASH');
is_deeply($h2, {e2 => 'bbb'});

# A class where we can modify the fromXML and toXML methods.

my ($from_xml, $to_xml);
package My::Class;
sub fromXML(@) { $from_xml->(@_) }
sub toXML(@)   { $to_xml->(@_) }

package main;

#
# test fromXML with Class name
#

$from_xml =
sub
{  my ($class, $data, $type) = @_;
   ok(1, 'fromXML called');
   is($class, 'My::Class');
   is($type, $type2);
   isa_ok($data, 'HASH');
   ok(exists $data->{e2});
   bless $data, 'My::Class';
};

my $r3 = create_reader $schema, "typemap class" => $type2
  , typemap => {$type2 => 'My::Class'};

ok(defined $r3, 'typemap reader from class');
my $h3 = $r3->('<test2><e2>aaa</e2></test2>');
is_deeply($h3, bless {e2 => 'aaa'}, 'My::Class');

#
# test fromXML with Object
#

my $interface = bless {}, 'My::Class';
$from_xml =
sub
{  my ($self, $data, $type) = @_;
   ok(1, 'fromXML called');
   isa_ok($self, 'My::Class');
   is_deeply($data, {e2 => 'ccc'});
   {e3 => 'donkey'};
};

my $r4 = create_reader $schema, "typemap object" => $type2
  , typemap => {$type2 => $interface};

ok(defined $r4, 'typemap reader from object');
my $h4 = $r4->('<test2><e2>ccc</e2></test2>');
is_deeply($h4, {e3 => 'donkey'});

#
# test toXML with CODE
#

@out = ();
my $someobj = bless {e2 => 'bbb'}, 'My::Class';
my $w2 = create_writer $schema, "toXML CODE" => $type2
  , typemap => {$type2 => sub {@out = @_; $_[1]}};

ok(defined $w2, 'typemap writer from code');
my $x2 = $w2->($doc, $someobj);

cmp_ok(scalar(@out), '==', 4, 'writer with CODE');
is($out[0], 'WRITER');
is_deeply($out[1], $someobj);
is($out[2], $type2);
isa_ok($out[3], 'XML::LibXML::Document');
compare_xml($x2, '<test2><e2>bbb</e2></test2>');

my $out = templ_perl $schema, "{$TestNS}test2", skip_header => 1
                    , typemap => { $type2 => '&function'};
is($out, <<__TEMPL);
# call on converter function with object
\$function->('WRITER', \$object, '{$TestNS}test2', \$doc)
__TEMPL

#
# test toXML with Class
#

$to_xml =
sub
{  my ($self, $type, $d) = @_;
   ok(1, 'toXML called');
   is_deeply($self, $someobj);
   isa_ok($self, 'My::Class');
   is($type, $type2);
   isa_ok($d, 'XML::LibXML::Document');
   $self;
};

my $w3 = create_writer $schema, "toXML Class" => $type2
  , typemap => {$type2 => 'My::Class'};

ok(defined $w3, 'typemap writer from class');
my $x3 = $w3->($doc, $someobj);
compare_xml($x3, '<test2><e2>bbb</e2></test2>');

$out = templ_perl $schema, "{$TestNS}test2", skip_header => 1
                    , typemap => { $type2 => 'My::Class'};
is($out, <<__TEMPL);
# calls toXML() on My::Class objects
#   with {http://test-types}test2 and doc
bless({}, 'My::Class')
__TEMPL

#
# test toXML with Object
#

$to_xml =
sub
{  my ($self, $obj, $type, $d) = @_;
   ok(1, 'toXML called');
   isa_ok($self, 'My::Class');
   isa_ok($obj, 'My::Class');  # usually some other type
   is_deeply($obj, $someobj);
   is($type, $type2);
   isa_ok($d, 'XML::LibXML::Document');
   $obj;
};

my $w4 = create_writer $schema, "toXML object" => $type2
  , typemap => {$type2 => $interface};

ok(defined $w4, 'typemap writer from object');
my $x4 = $w4->($doc, $someobj);
compare_xml($x4, '<test2><e2>bbb</e2></test2>');

$out = templ_perl $schema, "{$TestNS}test2", skip_header => 1
                , typemap => { $type2 => '$interface'};
is($out, <<__TEMPL);
# call on converter with object
\$interface->toXML(\$object, '{$TestNS}test2', \$doc)
__TEMPL
