#!/usr/bin/perl -w

package Mega::Doodle;
use VSO;
has 'name' => (
  is        => 'ro',
  isa       => 'Str',
  required  => 1,
);

package Mega::Whammo;
use VSO;
has 'name' => (
  is        => 'ro',
  isa       => 'Str',
  required  => 1,
);

package Foo;
use VSO;

package Bar;
use VSO;
extends 'Foo';

package Baz;
use VSO;
extends 'Bar';
has 'attr1';

package Bux;
use VSO;
extends 'Baz';
has 'ro_attr_plain' => (
  is      => 'ro'
);
has 'ro_attr_str' => (
  is      => 'ro',
  isa     => 'Any',
);

package Juan;
use VSO;

subtype 'SpanishWord' =>
  as    'Str',
  where { m{(?:o|a|es)$} },
  message { 'Spanish words end with o, a or es' };

subtype 'GirlieSpanishWord' =>
  as      'SpanishWord',
  where   { m{(?:so)$} },
  message { 'GirlieSpanishWord ends with so' };

coerce  'SpanishWord' =>
  from  'Str',
  via   { $_ .= 'o' };

coerce 'GirlieSpanishWord' =>
  from  'Str',
  via   { $_ .= 'so' };

has 'wordo' => (
  is        => 'ro',
  isa       => 'SpanishWord',
  required  => 1,
  coerce    => 1,
);

has 'girlie_word' => (
  is        => 'ro',
  isa       => 'GirlieSpanishWord',
  required  => 1,
  coerce    => 1,
);

package Objecto;
use VSO;

has 'md' => (
  is        => 'ro',
  isa       => 'Mega::Doodle|Mega::Whammo',
  required  => 1,
  coerce    => 1,
);

coerce 'Mega::Doodle' =>
  from    'Str',
  via     { Mega::Doodle->new( name => delete(shift->{md}) ) };

package main;

use strict;
use warnings 'all';
use Test::More 'no_plan';

DynamicSubtypes: {
  ok( my $foo = Foo->new(), 'Foo.new' );
  ok( my $bar = Bar->new(), 'Bar.new' );
  isa_ok $bar, 'Bar';
  isa_ok $bar, 'Foo';
  ok( my $baz = Baz->new(attr1=>'anything'), 'Baz.new' );
  is $baz->attr1 => 'anything', 'baz.attr1 is correct';
  ok(
    my $bux = Bux->new(
      attr1         => 'anything',
      ro_attr_plain => 'foo',
      ro_attr_str   => 'bar',
    ),
    'Bux.new'
  );


  ok(
    my $hola = Juan->new( wordo => 'hola', girlie_word => 'baz' ),
    'Juan.new'
  );

  ok(
    my $trucko = Juan->new( wordo => 'truck', girlie_word => 'bazzz' ),
    'Juan.new(truck -> trucko)'
  );
  is $trucko->wordo => 'trucko';
};


PackageTypes: {

  ok(
    my $mega = Mega::Doodle->new( name => 'Frank' ),
    'Mega::Doodle.new'
  );

  ok(
    my $objectA = Objecto->new(
      md  => Mega::Doodle->new(
        name  => 'Bob'
      )
    ),
    'Objecto.new(megadoodle object)'
  );

  ok(
    my $objectB = Objecto->new(
      md  => Mega::Whammo->new(
        name  => 'George'
      )
    ),
    'Objecto.new(megadoodle object)'
  );
  
  ok(
    my $objectC = Objecto->new( md => 'Bob' ),
    'Objecto.new(name -> Bob)'
  );
};


