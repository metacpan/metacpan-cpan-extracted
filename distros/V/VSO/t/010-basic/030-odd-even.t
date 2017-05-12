#!/user/bin/perl -w

package Ken;
use VSO;

subtype 'Number::Odd'
  => as 'Int'
  => where { $_ % 2 }
  => message { "$_ is not an odd number: %=:" . ($_ % 2) };

subtype 'Number::Even'
  => as 'Int'
  => where { (! $_) || ( $_ % 2 == 0 ) }
  => message { "$_ is not an even number" };

coerce 'Number::Odd'
  => from 'Int'
  => via  { $_ % 2 ? $_ : $_ + 1 };

coerce 'Number::Even'
  => from 'Int'
  => via { $_ % 2 ? $_ + 1 : $_ };

has 'favorite_number' => (
  is        => 'ro',
  isa       => 'Number::Odd',
  required  => 1,
  coerce    => 1, # Otherwise no coercion is performed.
);

package main;

use strict;
use warnings 'all';
use Test::More 'no_plan';

GOOD: {
  ok(
    my $ken = Ken->new( favorite_number => 3 ),
    'Ken.new(3)'
  );
  is $ken->favorite_number => 3;
}

EVEN2ODD: {
  ok(
    my $ken = Ken->new( favorite_number => 4 ),
    'Ken.new(4)'
  );
  is $ken->favorite_number => 5;
}

