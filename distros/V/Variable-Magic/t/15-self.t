#!perl

use strict;
use warnings;

use Test::More;

my $tests;
BEGIN { $tests = 18 }

plan tests => $tests;

use Variable::Magic qw<wizard cast dispell getdata MGf_LOCAL VMG_UVAR>;

use lib 't/lib';
use Variable::Magic::TestGlobalDestruction;

my $c = 0;

{
 my $wiz = eval {
  wizard data => sub { $_[0] },
         get  => sub { ++$c },
         free => sub { --$c }
 };
 is($@, '',             'wizard creation error doesn\'t croak');
 ok(defined $wiz,       'wizard is defined');
 is(ref $wiz, 'SCALAR', 'wizard is a scalar ref');

 my $res = eval { cast $wiz, $wiz };
 is($@, '', 'cast on self doesn\'t croak');
 ok($res,   'cast on self is valid');

 my $w = $wiz;
 is($c, 1, 'magic works correctly on self');

 $res = eval { dispell $wiz, $wiz };
 is($@, '', 'dispell on self doesn\'t croak');
 ok($res,   'dispell on self is valid');

 $w = $wiz;
 is($c, 1, 'magic is no longer invoked on self when dispelled');

 $res = eval { cast $wiz, $wiz, $wiz };
 is($@, '', 're-cast on self doesn\'t croak');
 ok($res,   're-cast on self is valid');

 $w = getdata $wiz, $wiz;
 is($c, 1, 'getdata on magical self doesn\'t trigger callbacks');

 $res = eval { dispell $wiz, $wiz };
 is($@, '', 're-dispell on self doesn\'t croak');
 ok($res,   're-dispell on self is valid');

 $res = eval { cast $wiz, $wiz };
 is($@, '', 're-re-cast on self doesn\'t croak');
 ok($res,   're-re-cast on self is valid');
}

{
 my %testcases;

 BEGIN {
  my %magics = do {
   my @magics = qw<get set len clear free copy>;
   push @magics, 'local'                       if MGf_LOCAL;
   push @magics, qw<fetch store exists delete> if VMG_UVAR;
   map { $_ => 1 } @magics;
  };

  %testcases = (
   SCALAR => {
    id    => 1,
    ctor  => sub { my $val = 123; \$val },
    tests => [
     get   => [ sub { my $val = ${$_[0]} }    => 123 ],
     set   => [ sub { ${$_[0]} = 456; $_[0] } => \456 ],
     free  => [ ],
    ],
   },
   ARRAY => {
    id    => 2,
    ctor  => sub { [ 0 .. 2 ]  },
    tests => [
     len   => [ sub { my $len = @{$_[0]} }   => 3   ],
     clear => [ sub { @{$_[0]} = (); $_[0] } => [ ] ],
     free  => [ ],
    ],
   },
   HASH => {
    id    => 3,
    ctor  => sub { +{ foo => 'bar' } },
    tests => [
     clear  => [ sub { %{$_[0]} = (); $_[0] }          => +{ }             ],
     free   => [ ],
     fetch  => [ sub { my $val = $_[0]->{foo} }        => 'bar'            ],
     store  => [ sub { $_[0]->{foo} = 'baz'; $_[0] }   => { foo => 'baz' } ],
     exists => [ sub { my $res = exists $_[0]->{foo} } => 1                ],
     delete => [ sub { my $val = delete $_[0]->{foo} } => 'bar'            ],
    ],
   },
  );

  my $count;

  for my $testcases (map $_->{tests}, values %testcases) {
   my $i = 0;
   while ($i < $#$testcases) {
    if ($magics{$testcases->[$i]}) {
     $i += 2;
     ++$count;
    } else {
     splice @$testcases, $i, 2;
    }
   }
  }

  $tests += $count * 2 * 2 * 3;
 }

 my @types = sort { $testcases{$a}->{id} <=> $testcases{$b}->{id} }
              keys %testcases;

 my $other_wiz = wizard data => sub { 'abc' };

 for my $type (@types) {
  my $ctor = $testcases{$type}->{ctor};

  my @testcases = @{$testcases{$type}->{tests}};
  while (@testcases >= 2) {
   my ($magic, $test) = splice @testcases, 0, 2;

   for my $dispell (0, 1) {
    for my $die (0, 1) {
     my $desc = $dispell ? 'dispell' : 'cast';
     $desc .= " a $type from a $magic callback";
     $desc .= ' and dieing' if $die;

     my $wiz;
     my $code = $dispell
                ? sub { &dispell($_[0], $wiz);    die 'oops' if $die; return }
                : sub { &cast($_[0], $other_wiz); die 'oops' if $die; return };
     $wiz = wizard(
      data   => sub { 'xyz' },
      $magic => $code,
     );

     my ($var, $res, $err);
     if ($magic eq 'free') {
      eval {
       my $v = $ctor->();
       &cast($v, $wiz);
      };
      $err = $@;
     } else {
      $var = $ctor->();
      &cast($var, $wiz);
      $res = eval {
       $test->[0]->($var);
      };
      $err = $@;
     }

     if ($die) {
      like $err, qr/^oops at/, "$desc: correct error";
      is $res, undef, "$desc: returned undef";
     } else {
      is $err, '', "$desc: no error";
      is_deeply $res, $test->[1], "$desc: returned value";
     }
     if (not defined $var) {
      pass "$desc: meaningless";
     } elsif ($dispell) {
      my $data = &getdata($var, $wiz);
      is $data, undef, "$desc: correctly dispelled";
     } else {
      my $data = &getdata($var, $other_wiz);
      is $data, 'abc', "$desc: correctly cast";
     }
    }
   }
  }
 }
}

SKIP: {
 skip "Called twice starting from perl 5.24" => 1 if "$]" >= 5.024;

 my $recasted = 0;

 my $wiz2 = wizard;
 my $wiz1 = wizard free => sub { ++$recasted; &cast($_[0], $wiz2); die 'xxx' };

 local $@;
 my $res = eval {
  my $v = do { my $val = 123; \$val };
  &cast($v, $wiz1);
 };

 is $recasted, 1, 'recasting free callback called only once';
}

eval q[
 use lib 't/lib';
 BEGIN { require Variable::Magic::TestDestroyRequired; }
];
is $@, '', 'wizard destruction at the end of BEGIN-time require doesn\'t panic';
