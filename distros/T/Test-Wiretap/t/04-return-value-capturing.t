#!/usr/bin/env perl

use Test::More tests => 16;

use lib 't/lib';
use lib 'lib';
use lib '../lib';
use Test::Wiretap;

{
  package ValueHolder;

  sub new {
    my ($class, $value) = @_;
    my $self = bless {} => $class;
    $self->set_attr($value);
    return $self;
  }
  sub set_attr {
    my ($self, $value) = @_;
    $self->{deeply_stored_value}[0] = $value;
  }
  sub get_attr {
    my ($self, $value) = @_;
    return $self->{deeply_stored_value}[0];
  }

  sub function {
    return wantarray ? qw(a list) : 'a-scalar';
  }
}

{
  package Utility;
  sub prefix_increment {
    my ($class, $obj) = @_;
    $obj->set_attr($obj->get_attr + 1);
    return $obj;
  }
}

# capturing of function args and return values
{
  my $tap = Test::Wiretap->new({
    name => 'ValueHolder::function',
    capture => 1,
  });

  is_deeply( $tap->return_values, [], '->return_values starts out sane' );
  is_deeply( $tap->return_contexts, [], '->return_contexts starts out sane' );

  my @list = ValueHolder::function(qw(a b c));
  my $scalar = ValueHolder::function(qw(d e f));
  ValueHolder::function(qw(g h i));

  is_deeply( $tap->return_values, [
    [qw(a list)],
    ['a-scalar'],
    undef,
  ], 'basic return-value capturing' );

  is_deeply( $tap->return_contexts, [
    'list',
    'scalar',
    'void',
  ], 'call context capturing' );

  $tap->reset;

  is_deeply( $tap->return_values, [], '->return_values gets reset by ->reset' );
  is_deeply( $tap->return_values, [], '->return_contexts gets reset by ->reset' );
}

# deep copying of return values + args
{
  my $object = ValueHolder->new(100);
  my $wt = Test::Wiretap->new({
    name => 'Utility::prefix_increment',
    capture => 1,
    # deep_copy defaults to on
  });

  my $returned_object = Utility->prefix_increment($object);
  $returned_object->set_attr(-3);

  is( $object->get_attr, -3, "function's return value is shallowly copied" );

  my $arg_object = $wt->method_args->[0][0];
  is( ref($arg_object), 'ValueHolder', 'sanity check: got the right argument' );
  is( $arg_object->get_attr, 100, 'copied arg object deeply' );

  my $ret_object = $wt->return_values->[0][0];
  is( ref($ret_object), 'ValueHolder', 'sanity check: got the right return value' );
  is( $ret_object->get_attr, 101, 'copied return value deeply' );
}

# you can turn off deep copying, but it's on by default
{
  my $object = ValueHolder->new(100);
  my $wt = Test::Wiretap->new({
    name => 'Utility::prefix_increment',
    capture => 1,
    deep_copy => undef,      # any false value turns it off
  });

  my $returned_object = Utility->prefix_increment($object);
  $returned_object->set_attr(-3);

  is( $object->get_attr, -3, "function's return value is shallowly copied (2)" );

  my $arg_object = $wt->method_args->[0][0];
  is( ref($arg_object), 'ValueHolder', 'sanity check: got the right argument' );
  is( $arg_object->get_attr, -3, 'copied arg object shallowly' );

  my $ret_object = $wt->return_values->[0][0];
  is( ref($ret_object), 'ValueHolder', 'sanity check: got the right return value' );
  is( $ret_object->get_attr, -3, 'copied ->return_values shallowly' );
}
