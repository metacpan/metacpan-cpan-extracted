#!perl

use strict;
use warnings;

use Variable::Magic qw<
 wizard cast dispell getdata
 VMG_OP_INFO_NAME VMG_OP_INFO_OBJECT
>;

use lib 't/lib';
use VPIT::TestHelpers (
 threads => [ 'Variable::Magic' => 'Variable::Magic::VMG_THREADSAFE()' ],
);

use Test::Leaner 'no_plan';

my $destroyed : shared = 0;
my $c         : shared = 0;

sub spawn_wiz {
 my ($op_info) = @_;

 my $desc = "wizard with op_info $op_info in main thread";

 local $@;
 my $wiz = eval {
  wizard(
   data    => sub { $_[1] + threads->tid() },
   get     => sub { lock $c; ++$c; 0 },
   set     => sub {
    my $op = $_[-1];
    my $tid = threads->tid();

    if ($op_info == VMG_OP_INFO_OBJECT) {
     is_deeply { class => ref($op),   name => $op->name },
               { class => 'B::BINOP', name => 'sassign' },
               "op object in thread $tid is correct";
    } else {
     is $op, 'sassign', "op name in thread $tid is correct";
    }

    return 0
   },
   free    => sub { lock $destroyed; ++$destroyed; 0 },
   op_info => $op_info,
  );
 };
 is $@,     '',    "$desc doesn't croak";
 isnt $wiz, undef, "$desc is defined";
 is $c,     0,     "$desc doesn't trigger magic";

 return $wiz;
}

sub try {
 my ($dispell, $wiz) = @_;
 my $tid = threads->tid;

 my $a = 3;

 {
  local $@;
  my $res = eval { cast $a, $wiz, sub { 5 }->() };
  is $@, '', "cast in thread $tid doesn't croak";
 }

 {
  local $@;
  my $b;
  eval { $b = $a };
  is $@, '', "get in thread $tid doesn't croak";
  is $b, 3,  "get in thread $tid returns the right thing";
 }

 {
  local $@;
  my $d = eval { getdata $a, $wiz };
  is $@, '',       "getdata in thread $tid doesn't croak";
  is $d, 5 + $tid, "getdata in thread $tid returns the right thing";
 }

 {
  local $@;
  eval { $a = 9 };
  is $@, '', "set in thread $tid (check opname) doesn't croak";
 }

 if ($dispell) {
  {
   local $@;
   my $res = eval { dispell $a, $wiz };
   is $@, '', "dispell in thread $tid doesn't croak";
  }

  {
   local $@;
   my $b;
   eval { $b = $a };
   is $@, '', "get in thread $tid after dispell doesn't croak";
   is $b, 9,  "get in thread $tid after dispell returns the right thing";
  }
 }

 return 1;
}

my $wiz_name = spawn_wiz VMG_OP_INFO_NAME;
my $wiz_obj  = spawn_wiz VMG_OP_INFO_OBJECT;

for my $dispell (1, 0) {
 for my $wiz ($wiz_name, $wiz_obj) {
  {
   lock $c;
   $c = 0;
  }
  {
   lock $destroyed;
   $destroyed = 0;
  }

  my $completed = 0;

  my @threads = map spawn(\&try, $dispell, $wiz), 1 .. 2;
  for my $thr (@threads) {
   my $res = $thr->join;
   $completed += $res if defined $res;
  }

  {
   lock $c;
   is $c, $completed, "get triggered twice";
  }
  {
   lock $destroyed;
   is $destroyed, (1 - $dispell) * $completed, 'destructors';
  }
 }
}

{
 my @threads;
 my $flag : shared = 0;
 my $destroyed;

 {
  my $wiz = wizard(
   set => sub {
    my $tid = threads->tid;
    pass "set callback called in thread $tid"
   },
   free => sub { ++$destroyed },
  );

  my $var = 123;
  cast $var, $wiz;

  @threads = map spawn(
   sub {
    my $tid = threads->tid;
    my $exp = 456 + $tid;
    {
     lock $flag;
     threads::shared::cond_wait($flag) until $flag;
    }
    $var = $exp;
    is $var, $exp, "\$var could be assigned to in thread $tid";
   }
  ), 1 .. 5;
 }

 is $destroyed, 1, 'wizard is destroyed';

 {
  lock $flag;
  $flag = 1;
  threads::shared::cond_broadcast($flag);
 }

 $_->join for @threads;
}
