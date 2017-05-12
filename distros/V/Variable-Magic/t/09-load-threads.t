#!perl

use strict;
use warnings;

my ($module, $thread_safe_var);
BEGIN {
 $module          = 'Variable::Magic';
 $thread_safe_var = 'Variable::Magic::VMG_THREADSAFE()';
}

sub load_test {
 my $res = 0;
 if (defined &Variable::Magic::wizard) {
  my $wiz = Variable::Magic::wizard(
   free => sub { $res = 1; return },
  );
  my $var;
  &Variable::Magic::cast(\$var, $wiz);
  $res = 2;
 }
 return $res;
}

# Keep the rest of the file untouched

use lib 't/lib';
use VPIT::TestHelpers threads => [ $module, $thread_safe_var ];

my $could_not_create_thread = 'Could not create thread';

use Test::Leaner;

sub is_loaded {
 my ($affirmative, $desc) = @_;

 my $res = load_test();

 my $expected;
 if ($affirmative) {
  $expected = 1;
  $desc     = "$desc: module loaded";
 } else {
  $expected = 0;
  $desc     = "$desc: module not loaded";
 }

 unless (is $res, $expected, $desc) {
  $res      = defined $res ? "'$res'" : 'undef';
  $expected = "'$expected'";
  diag("Test '$desc' failed: got $res, expected $expected");
 }

 return;
}

BEGIN {
 local $@;
 my $code = eval "sub { require $module }";
 die $@ if $@;
 *do_load = $code;
}

is_loaded 0, 'main body, beginning';

# Test serial loadings

SKIP: {
 my $thr = spawn(sub {
  my $here = "first serial thread";
  is_loaded 0, "$here, beginning";

  do_load;
  is_loaded 1, "$here, after loading";

  return;
 });

 skip "$could_not_create_thread (serial 1)" => 2 unless defined $thr;

 $thr->join;
 if (my $err = $thr->error) {
  die $err;
 }
}

is_loaded 0, 'main body, in between serial loadings';

SKIP: {
 my $thr = spawn(sub {
  my $here = "second serial thread";
  is_loaded 0, "$here, beginning";

  do_load;
  is_loaded 1, "$here, after loading";

  return;
 });

 skip "$could_not_create_thread (serial 2)" => 2 unless defined $thr;

 $thr->join;
 if (my $err = $thr->error) {
  die $err;
 }
}

is_loaded 0, 'main body, after serial loadings';

# Test nested loadings

SKIP: {
 my $parent = spawn(sub {
  my $here = 'parent thread';
  is_loaded 0, "$here, beginning";

  SKIP: {
   my $kid = spawn(sub {
    my $here = 'child thread';
    is_loaded 0, "$here, beginning";

    do_load;
    is_loaded 1, "$here, after loading";

    return;
   });

   skip "$could_not_create_thread (nested child)" => 2 unless defined $kid;

   $kid->join;
   if (my $err = $kid->error) {
    die "in child thread: $err\n";
   }
  }

  is_loaded 0, "$here, after child terminated";

  do_load;
  is_loaded 1, "$here, after loading";

  return;
 });

 skip "$could_not_create_thread (nested parent)" => (3 + 2)
                                                         unless defined $parent;

 $parent->join;
 if (my $err = $parent->error) {
  die $err;
 }
}

is_loaded 0, 'main body, after nested loadings';

# Test parallel loadings

use threads;
use threads::shared;

my $sync_points = 7;

my @locks_down = (1) x $sync_points;
my @locks_up   = (0) x $sync_points;
share($_) for @locks_down, @locks_up;

my $default_peers = 2;

sub sync_master {
 my ($id, $peers) = @_;

 $peers = $default_peers unless defined $peers;

 {
  lock $locks_down[$id];
  $locks_down[$id] = 0;
  cond_broadcast $locks_down[$id];
 }

 LOCK: {
  lock $locks_up[$id];
  my $timeout = time() + 10;
  until ($locks_up[$id] == $peers) {
   if (cond_timedwait $locks_up[$id], $timeout) {
    last LOCK;
   } else {
    return 0;
   }
  }
 }

 return 1;
}

sub sync_slave {
 my ($id) = @_;

 {
  lock $locks_down[$id];
  cond_wait $locks_down[$id] until $locks_down[$id] == 0;
 }

 {
  lock $locks_up[$id];
  $locks_up[$id]++;
  cond_signal $locks_up[$id];
 }

 return 1;
}

for my $first_thread_ends_first (0, 1) {
 for my $id (0 .. $sync_points - 1) {
  {
   lock $locks_down[$id];
   $locks_down[$id] = 1;
  }
  {
   lock $locks_up[$id];
   $locks_up[$id] = 0;
  }
 }

 my $thr1_end = 'finishes first';
 my $thr2_end = 'finishes last';

 ($thr1_end, $thr2_end) = ($thr2_end, $thr1_end)
                                                unless $first_thread_ends_first;

 SKIP: {
  my $thr1 = spawn(sub {
   my $here = "first simultaneous thread ($thr1_end)";
   sync_slave 0;

   is_loaded 0, "$here, beginning";
   sync_slave 1;

   do_load;
   is_loaded 1, "$here, after loading";
   sync_slave 2;
   sync_slave 3;

   sync_slave 4;
   is_loaded 1, "$here, still loaded while also loaded in the other thread";
   sync_slave 5;

   sync_slave 6 unless $first_thread_ends_first;

   is_loaded 1, "$here, end";

   return 1;
  });

  skip "$could_not_create_thread (parallel 1)" => (4 * 2) unless defined $thr1;

  my $thr2 = spawn(sub {
   my $here = "second simultaneous thread ($thr2_end)";
   sync_slave 0;

   is_loaded 0, "$here, beginning";
   sync_slave 1;

   sync_slave 2;
   sync_slave 3;
   is_loaded 0, "$here, loaded in other thread but not here";

   do_load;
   is_loaded 1, "$here, after loading";
   sync_slave 4;
   sync_slave 5;

   sync_slave 6 if $first_thread_ends_first;

   is_loaded 1, "$here, end";

   return 1;
  });

  sync_master($_) for 0 .. 5;

  if (defined $thr2) {
   ($thr2, $thr1) = ($thr1, $thr2) unless $first_thread_ends_first;

   $thr1->join;
   if (my $err = $thr1->error) {
    die $err;
   }

   sync_master(6, 1);

   $thr2->join;
   if (my $err = $thr1->error) {
    die $err;
   }
  } else {
   sync_master(6, 1) unless $first_thread_ends_first;

   $thr1->join;
   if (my $err = $thr1->error) {
    die $err;
   }

   skip "$could_not_create_thread (parallel 2)" => (4 * 1);
  }
 }

 is_loaded 0, 'main body, after simultaneous threads';
}

# Test simple clone

SKIP: {
 my $parent = spawn(sub {
  my $here = 'simple clone, parent thread';
  is_loaded 0, "$here, beginning";

  do_load;
  is_loaded 1, "$here, after loading";

  SKIP: {
   my $kid = spawn(sub {
    my $here = 'simple clone, child thread';

    is_loaded 1, "$here, beginning";

    return;
   });

   skip "$could_not_create_thread (simple clone child)" => 1
                                                            unless defined $kid;

   $kid->join;
   if (my $err = $kid->error) {
    die "in child thread: $err\n";
   }
  }

  is_loaded 1, "$here, after child terminated";

  return;
 });

 skip "$could_not_create_thread (simple clone parent)" => (3 + 1)
                                                         unless defined $parent;

 $parent->join;
 if (my $err = $parent->error) {
  die $err;
 }
}

is_loaded 0, 'main body, after simple clone';

# Test clone outliving its parent

SKIP: {
 my $kid_done;
 share($kid_done);

 my $parent = spawn(sub {
  my $here = 'outliving clone, parent thread';
  is_loaded 0, "$here, beginning";

  do_load;
  is_loaded 1, "$here, after loading";

  my $kid_tid;

  SKIP: {
   my $kid = spawn(sub {
    my $here = 'outliving clone, child thread';

    is_loaded 1, "$here, beginning";

    {
     lock $kid_done;
     cond_wait $kid_done until $kid_done;
    }

    is_loaded 1, "$here, end";

    return 1;
   });

   if (defined $kid) {
    $kid_tid = $kid->tid;
   } else {
    $kid_tid = 0;
    skip "$could_not_create_thread (outliving clone child)" => 2;
   }
  }

  is_loaded 1, "$here, end";

  return $kid_tid;
 });

 skip "$could_not_create_thread (outliving clone parent)" => (3 + 2)
                                                         unless defined $parent;

 my $kid_tid = $parent->join;
 if (my $err = $parent->error) {
  die $err;
 }

 if ($kid_tid) {
  my $kid = threads->object($kid_tid);
  if (defined $kid) {
   if ($kid->is_running) {
    lock $kid_done;
    $kid_done = 1;
    cond_signal $kid_done;
   }

   $kid->join;
  }
 }
}

is_loaded 0, 'main body, after outliving clone';

do_load;
is_loaded 1, 'main body, loaded at end';

done_testing();
