#!perl

use strict;
use warnings;

use lib 't/lib';
use VPIT::TestHelpers threads => [ 'indirect' => 'indirect::I_THREADSAFE()' ];

use Test::Leaner;

sub expect {
 my ($pkg) = @_;
 qr/^Indirect call of method "new" on object "$pkg" at \(eval \d+\) line \d+/;
}

my $error;

no indirect 'global', 'hook' => sub { $error = indirect::msg(@_) };

sub try {
 my $tid = threads->tid();

 for my $run (1 .. 2) {
  my $desc  = "global indirect hook (thread $tid, run $run)";
  my $class = "Mango$tid";
  my @warns;
  {
   local $SIG{__WARN__} = sub { push @warns, @_ };
   eval "return; my \$x = new $class 1, 2;"
  }
  is        $@,      '',             "$desc: did not croak";
  is_deeply \@warns, [ ],            "$desc: no warnings";
  like      $error,  expect($class), "$desc: correct error";
 }
}

my @threads = map spawn(\&try), 1 .. 10;

$_->join for @threads;

pass 'done';

done_testing;
