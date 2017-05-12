#!/usr/bin/perl -w
###########################################################################
### 00________object.t
###
### Basic tests of Trinket::Object
###
### $Id: 00________object.t,v 1.2 2001/02/19 20:03:26 deus_x Exp $
###
### TODO:
###  -- Add tests for data types
###
###########################################################################

no warnings qw( uninitialized );
use strict;
use Test;

BEGIN
  {
    plan tests => 21;

    unless(grep /blib/, @INC)
      {
        chdir 't' if -d 't';
        unshift @INC, '../lib' if -d '../lib';
        unshift @INC, './lib' if -d './lib';
      }
  }

use Trinket::Object;
use Carp qw( croak cluck );

my ($obj);

### Creation
ok $obj = new Trinket::Object();

### Initialization
ok $obj = new Trinket::Object
  ({
    id => '1',
   });

### Setting a non-existent property
eval ' $obj->set_foo("test"); ';
ok $@ =~ /No such property 'foo' to set/;

### Getting a non-existent property
eval ' $obj->get_foo("test"); ';
ok $@ =~ /No such property 'foo' to get/;

### Adding a property
ok $obj->add_property
  ( foo => 'char', 0, 'The foo property' );

### Setting a new property
ok $obj->set_foo("test");

### Getting a new property
ok $obj->get_foo() eq 'test';

### Creating a subclass
ok $obj = new TestObject();

### Testing inherited class metadata
ok defined $TestObject::PROPERTIES{id};

### Testing an accessor override, and imported constants.
ok $obj->get_baz() eq META_PROP_INDEXED;

### Create a new object and check the dirty fields
$obj = new TestObject();
my ($dirty, $wrong, $name, $vals);

### Assert that the only dirty field on object creation should be 'class'
$dirty = $obj->_find_dirty();
$wrong = 0;
while (($name, $vals) = each %{$dirty})
  { $wrong++ if ($name ne 'class'); }
ok $wrong == 0;

### Also, assert that the dirty field old value should be null and
### that the new is 'TestObject'.
ok ($dirty->{class}->[0] eq '') &&
  ($dirty->{class}->[1] eq 'TestObject');

### Clean all dirty flags.  Any remaining dirty properties are wrong.
$obj->_clean_all();
$dirty = $obj->_find_dirty();
$wrong = 0;
while (($name, $vals) = each %{$dirty})
  { $wrong++; }
ok $wrong == 0;

### Add two properties: one indexed, one not.
$obj->add_property( foo   => 'char', 1, 'The foo property' );
$obj->add_property( xzzxy => 'char', 0, 'The xzzxy property' );

### Neither new property should be dirty
$dirty = $obj->_find_dirty();
ok (!defined $dirty->{foo}) && (!defined $dirty->{xzzxy});

### Property 'xzzxy' should be *not* a dirty index after setting.
$obj->set_xzzxy("Nothing happens.");
$dirty = $obj->_find_dirty_indices();
ok !defined $dirty->{xzzxy};

### However, the property *should* be dirty in general.
$dirty = $obj->_find_dirty();
ok defined $dirty->{xzzxy};

### Property 'foo' should be a dirty index after setting.
$obj->set_foo("borkborkbork");
$dirty = $obj->_find_dirty_indices();
ok defined $dirty->{foo};

### 'foo' should also be dirty in general.
$dirty = $obj->_find_dirty();
ok defined $dirty->{foo};

### Clear the dirty flags, set the 'foo' property again, check whether
### the previous value was saved when the property is set as dirty.
$obj->_clean_all();
$obj->set_foo("A m00se once bit my sister.");
$dirty = $obj->_find_dirty();
ok ($dirty->{foo}->[DIRTY_OLD_VALUE] eq 'borkborkbork') &&
  ($dirty->{foo}->[DIRTY_NEW_VALUE] eq 'A m00se once bit my sister.');

$obj->remove_property('foo');
$obj->remove_property('xzzxy');

eval ' $obj->set_foo("test"); ';
ok $@ =~ /No such property 'foo' to set/;

eval ' $obj->set_xzzxy("test"); ';
ok $@ =~ /No such property 'xzzxy' to set/;

exit(0);

# {{{ TestObject class

{
  package TestObject;

  BEGIN
    {
      our $VERSION      = "0.0";
      our @ISA          = qw( Trinket::Object );
      our $DESCRIPTION  = 'Test object class';
      our %PROPERTIES   =
        (
         ### name => [ type, indexed, desc ]
         mung       => [ 'char', 1, 'Mung'     ],
         bar        => [ 'char', 1, 'Bar'      ],
         baz        => [ 'char', 1, 'Baz'      ],
        );
      Trinket::Object::import();
    }

  sub get_baz
    {
      my $self = shift;

      return META_PROP_INDEXED;
    }
}

# }}}
