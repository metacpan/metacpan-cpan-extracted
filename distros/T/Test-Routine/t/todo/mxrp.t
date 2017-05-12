#!/bin/env perl
use strict;
use warnings;

use Test::Routine::Util;
use Test::More;

BEGIN { plan skip_all => 'Test::Routine and MXRP not yet compatible'; }

{
  package Test::ThingHasID;
  use MooseX::Role::Parameterized;
  use Test::Routine;
  use Test::More;

  parameter id_method => (
    is  => 'ro',
    isa => 'Str',
    default => 'id',
  );

  role {
    my $p = shift;
    my $id_method = $p->id_method;

    requires $id_method;

    test thing_has_numeric_id => sub {
      my ($self) = @_;

      my $id = $self->$id_method;
      like($id, qr/\A[0-9]+\z/, "the thing's id is a string of ascii digits");
    };
  }
}

{
  package HasIdentifier;
  use Moose;
  with 'Test::ThingHasID' => { id_method => 'identifier' };

  sub identifier { return 123 }
}

run_tests(
  "we can use mxrp",
  'HasIdentifier',
);

# ...and we're done!
done_testing;
