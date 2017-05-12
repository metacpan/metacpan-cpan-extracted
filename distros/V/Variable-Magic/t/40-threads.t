#!perl

use strict;
use warnings;

use lib 't/lib';
use VPIT::TestHelpers (
 threads => [ 'Variable::Magic' => 'Variable::Magic::VMG_THREADSAFE()' ],
);

use Test::Leaner 'no_plan';

my $destroyed : shared = 0;

sub try {
 my ($dispell, $op_info) = @_;
 my $tid = threads->tid;

 my $c = 0;
 my $wiz;

 {
  local $@;
  eval { require Variable::Magic; 1 } or return;
 }

 {
  local $@;
  $wiz = eval {
   Variable::Magic::wizard(
    data    => sub { $_[1] + $tid },
    get     => sub { ++$c; 0 },
    set     => sub {
     my $op = $_[-1];

     if ($op_info eq 'object') {
      is_deeply { class => ref($op),   name => $op->name },
                { class => 'B::BINOP', name => 'sassign' },
                "op object in thread $tid is correct";
     } else {
      is $op, 'sassign', "op name in thread $tid is correct";
     }

     return 0;
    },
    free    => sub { lock $destroyed; ++$destroyed; 0 },
    op_info => $op_info eq 'object' ? Variable::Magic::VMG_OP_INFO_OBJECT()
                                    : Variable::Magic::VMG_OP_INFO_NAME()
   );
  };
  is $@,     '',    "wizard in thread $tid doesn't croak";
  isnt $wiz, undef, "wizard in thread $tid is defined";
  is $c,     0,     "wizard in thread $tid doesn't trigger magic";
 }

 my $a = 3;

 {
  local $@;
  my $res = eval { &Variable::Magic::cast(\$a, $wiz, sub { 5 }->()) };
  is $@, '', "cast in thread $tid doesn't croak";
  is $c, 0,  "cast in thread $tid doesn't trigger magic";
 }

 {
  local $@;
  my $b;
  eval { $b = $a };
  is $@, '', "get in thread $tid doesn't croak";
  is $b, 3,  "get in thread $tid returns the right thing";
  is $c, 1,  "get in thread $tid triggers magic";
 }

 {
  local $@;
  my $d = eval { &Variable::Magic::getdata(\$a, $wiz) };
  is $@, '',       "getdata in thread $tid doesn't croak";
  is $d, 5 + $tid, "getdata in thread $tid returns the right thing";
  is $c, 1,        "getdata in thread $tid doesn't trigger magic";
 }

 {
  local $@;
  eval { $a = 9 };
  is $@, '', "set in thread $tid (check opname) doesn't croak";
 }

 if ($dispell) {
  {
   local $@;
   my $res = eval { &Variable::Magic::dispell(\$a, $wiz) };
   is $@, '', "dispell in thread $tid doesn't croak";
   is $c, 1,  "dispell in thread $tid doesn't trigger magic";
  }

  {
   local $@;
   my $b;
   eval { $b = $a };
   is $@, '', "get in thread $tid after dispell doesn't croak";
   is $b, 9,  "get in thread $tid after dispell returns the right thing";
   is $c, 1,  "get in thread $tid after dispell doesn't trigger magic";
  }
 }

 return 1;
}

for my $dispell (1, 0) {
 {
  lock $destroyed;
  $destroyed = 0;
 }

 my $completed = 0;

 my @threads = map spawn(\&try, $dispell, $_), ('name') x 2, ('object') x 2;
 for my $thr (@threads) {
  my $res = $thr->join;
  $completed += $res if defined $res;
 }

 {
  lock $destroyed;
  is $destroyed, (1 - $dispell) * $completed, 'destructors';
 }
}
