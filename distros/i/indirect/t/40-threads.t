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

{
 no indirect;

 sub try {
  my $tid = threads->tid();

  for (1 .. 2) {
   {
    my $class = "Coconut$tid";
    my @warns;
    {
     local $SIG{__WARN__} = sub { push @warns, @_ };
     eval 'die "the code compiled but it shouldn\'t have\n";
           no indirect ":fatal"; my $x = new ' . $class . ' 1, 2;';
    }
    like         $@ || '', expect($class),
                      "\"no indirect\" in eval in thread $tid died as expected";
    is_deeply \@warns, [ ],
                      "\"no indirect\" in eval in thread $tid didn't warn";
   }

SKIP:
   {
    skip 'Hints aren\'t propagated into eval STRING below perl 5.10' => 3
                                                           unless "$]" >= 5.010;
    my $class = "Pineapple$tid";
    my @warns;
    {
     local $SIG{__WARN__} = sub { push @warns, @_ };
     eval 'return; my $y = new ' . $class . ' 1, 2;';
    }
    is $@, '',
             "\"no indirect\" propagated into eval in thread $tid didn't croak";
    my $first = shift @warns;
    like $first || '', expect($class),
              "\"no indirect\" propagated into eval in thread $tid warned once";
    is_deeply \@warns, [ ],
         "\"no indirect\" propagated into eval in thread $tid warned just once";
   }
  }
 }
}

my @threads = map spawn(\&try), 1 .. 10;

$_->join for @threads;

pass 'done';

done_testing;
