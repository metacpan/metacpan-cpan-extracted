#!perl -T

use strict;
use warnings;

BEGIN { delete $ENV{PERL_TEST_LEANER_USES_TEST_MORE} }

use Test::Leaner tests => 21 + 2 + 1 + 2;

my $lacunary = [ [ 1, 2, 3 ] => [ 1, 2, 3 ] ];
delete $lacunary->[0]->[1];
$lacunary->[1]->[1] = undef;

my $scalar_ref = \1;
my $array_ref  = [ ];
my $hash_ref   = { };
my $code_ref   = sub { };

my @tests = (
 [ undef, undef ],

 [ 1   => 1   ],
 [ 'a' => 'a' ],

 [ \1      => \1      ],
 [ \'a'    => \'a'    ],
 [ \(\1)   => \(\1)   ],
 [ \(\'a') => \(\'a') ],

 [ [ 1 ]   => [ 1 ]   ],
 [ [ 'a' ] => [ 'a' ] ],
 [ [ \1 ]  => [ \1 ]  ],

 [ [ 1, 2, 3 ]     => [ 1, 2, 3 ] ],
 [ [ 1, undef, 3 ] => [ 1, undef, 3 ] ],
 $lacunary,

 [ { a => 1 }     => { a => 1 }     ],
 [ { a => undef } => { a => undef } ],
 [ { a => \1 }    => { a => \1 }    ],

 [ { a => [ 1, undef, 2 ], b => \3 } => { a => [ 1, undef, 2 ], b => \3 } ],

 [ $scalar_ref => $scalar_ref ],
 [ $array_ref  => $array_ref  ],
 [ $hash_ref   => $hash_ref   ],
 [ $code_ref   => $code_ref   ],
);

# Test breaking encapsulation

{
 package Test::Leaner::TestIsDeeplyObject;

 sub new {
  my $class = shift;

  bless { @_ }, $class;
 }
}

{
 package Test::Leaner::TestIsDeeplyObject2;

 sub new {
  my $class = shift;

  bless { @_ }, $class;
 }
}

push @tests, (
 [ map Test::Leaner::TestIsDeeplyObject->new(
  a => [ 1, { b => 2, c => undef }, undef, \3 ],
  c => { d => \(\4), e => [ 5, undef ] },
 ), 1 .. 2 ],
 [
  Test::Leaner::TestIsDeeplyObject->new(a => 1),
  Test::Leaner::TestIsDeeplyObject2->new(a => 1),
 ],
);

{
 package Test::Leaner::TestIsDeeplyOverload;

 use overload 'eq' => sub {
  my ($x, $y, $r) = @_;

  $x = $x->{str};
  $y = $y->{str} if ref $y;

  ($x, $y) = ($y, $x) if $r;

  return $x eq $y;
 };

 sub new { bless { str => $_[1] }, $_[0] }
}

push @tests, [ map Test::Leaner::TestIsDeeplyOverload->new('foo'), 1 .. 2 ];

for my $t (@tests) {
 is_deeply $t->[0], $t->[1];
}

# Test vivification of deleted elements of an array

{
 my @l = (1);
 $l[2] = 3;
 is_deeply \@l, [ 1, undef, 3 ];
 delete $l[2];
 is_deeply \@l, [ 1 ];
}
