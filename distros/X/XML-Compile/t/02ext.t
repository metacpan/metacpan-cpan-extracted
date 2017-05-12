#!/usr/bin/env perl
# Check implementation of type extension administration

use warnings;
use strict;

use File::Spec;

use lib 'lib', 't';
use Test::More tests => 20;
use XML::Compile::Schema;
use XML::Compile::Util qw/pack_type/;
use TestTools;

my $s   = XML::Compile::Schema->new( <<_SCHEMA );
<schema targetNamespace="$TestNS"
        xmlns="$SchemaNS"
        xmlns:me="$TestNS">

<simpleType name="t1">
  <restriction base="int" />
</simpleType>

<simpleType name="t2">
  <restriction base="me:t1">
    <minInclusive value="10" />
  </restriction>
</simpleType>

<complexType name="t3">
  <simpleContent>
    <extension base="me:t2">
      <attribute name="a2_a" type="int" />
    </extension>
  </simpleContent>
</complexType>

</schema>
_SCHEMA

sub does_extend($$)
{   my ($f, $g) = @_;
    $f = pack_type $SchemaNS, $f if $f !~ m/^\{/;
    $g = pack_type $SchemaNS, $g if $g !~ m/^\{/;
    ok($s->doesExtend($f, $g), "$_[0] <- $_[1]");
}

sub does_not_extend($$)
{   my ($f, $g) = @_;
    $f = pack_type $SchemaNS, $f if $f !~ m/^\{/;
    $g = pack_type $SchemaNS, $g if $g !~ m/^\{/;
    ok(!$s->doesExtend($f, $g), "not $_[0] <- $_[1]");
}

does_extend     'anyType',       'anyType';
does_extend     'anySimpleType', 'anyType';
does_not_extend 'anyType',       'anySimpleType';

does_extend     'unsignedByte',  'unsignedShort';
does_extend     'unsignedByte',  'unsignedInt';
does_extend     'unsignedByte',  'unsignedLong';
does_extend     'unsignedByte',  'nonNegativeInteger';
does_extend     'unsignedByte',  'integer';
does_extend     'unsignedByte',  'decimal';
does_extend     'unsignedByte',  'anyAtomicType';
does_extend     'unsignedByte',  'anySimpleType';
does_extend     'unsignedByte',  'anyType';

does_extend	pack_type($TestNS,'t1'), pack_type($TestNS, 't1');
does_extend	pack_type($TestNS,'t1'), 'int';
does_extend	pack_type($TestNS,'t2'), 'int';
does_extend	pack_type($TestNS,'t2'), pack_type($TestNS, 't1');
does_extend	pack_type($TestNS,'t1'), 'anySimpleType';
does_extend	pack_type($TestNS,'t2'), 'anySimpleType';

does_extend	pack_type($TestNS,'t3'), pack_type($TestNS, 't2');
does_extend	pack_type($TestNS,'t3'), pack_type($TestNS, 't1');
