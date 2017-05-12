#!perl -T

use strict;
use warnings;

use Test::More;

BEGIN { delete $ENV{PERL_TEST_LEANER_USES_TEST_MORE} }

use Test::Leaner ();

use lib 't/lib';
use Test::Leaner::TestHelper;

my $buf;
capture_to_buffer $buf
             or plan skip_all =>'perl 5.8 required to test is_deeply() failing';

plan tests => 3 * 2 * (32 + 1 + 2);

my $shrunk = [ [ 1, 2, 3 ] => [ 1, 2, 3 ] ];
delete $shrunk->[0]->[2];
$shrunk->[1]->[2] = undef;

my $scalar_ref = \1;
my $array_ref  = [ ];
my $hash_ref   = { };
my $code_ref   = sub { };

my @tests = (
 [ undef, '' ],
 [ undef, 0  ],

 [ 1   => 2     ],
 [ 1   => '1.0' ],
 [ 1   => '1e0' ],
 [ 'a' => 'A'   ],
 [ 'a' => 'a '  ],

 [ \1      => \2    ],
 [ \(\1)   => \(\2) ],

 [ [ undef ] => [ ]    ],
 [ [ undef ] => [ 0 ]  ],
 [ [ undef ] => [ '' ] ],
 [ [ 0 ]     => [ ]    ],
 [ [ 0 ]     => [ '' ] ],
 [ [ '' ]    => [ ]    ],

 [ [ \1 ] => [ \"1.0" ] ],

 [ [ 1, undef, 3 ] => [ 1, 2, 3 ] ],
 [ [ 1, 2, undef ] => [ 1, 2 ] ],
 $shrunk,

 [ { a => undef } => { }         ],
 [ { a => undef } => { a => 0 }  ],
 [ { a => undef } => { a => '' } ],
 [ { a => 0 }     => { }         ],
 [ { a => 0 }     => { a => '' } ],
 [ { a => '' }    => { }         ],

 [ { a => 1 } => { 'A' => 1 } ],
 [ { a => 1 } => { 'a' => \"1.0" } ],

 [ [ { a => 1 }, 2, { b => \3 } ] => [ { a => 1 }, 2, { b => \'3.0' } ] ],

 [ $scalar_ref => "$scalar_ref" ],
 [ $array_ref  => "$array_ref"  ],
 [ $hash_ref   => "$hash_ref"   ],
 [ $code_ref   => "$code_ref"   ],
);

{
 package Test::Leaner::TestIsDeeplyObject;

 sub new {
  my $class = shift;

  bless { @_ }, $class;
 }
}

push @tests, [
 Test::Leaner::TestIsDeeplyObject->new(a => 1),
 Test::Leaner::TestIsDeeplyObject->new(a => 2),
];

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

push @tests, (
 [ map Test::Leaner::TestIsDeeplyOverload->new($_), qw<abc def> ],
 [ 'abc' => Test::Leaner::TestIsDeeplyOverload->new('abc') ],
);

my $count = 0;

@tests = map {
 $_, [ $_->[1], $_->[0] ]
} @tests;

for my $t (@tests) {
 reset_buffer {
  local $@;
  my $ret = eval { Test::Leaner::is_deeply($t->[0], $t->[1]) };
  ++$count if $@ eq '';
  is $@,    '',               'is_deeply(...) does not croak';
  ok !$ret,                   'is_deeply(...) returns false';
  is $buf, "not ok $count\n", 'is_deeply(...) produces the correct TAP code';
 }
}
