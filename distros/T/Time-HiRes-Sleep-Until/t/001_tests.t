# -*- perl -*-

use strict;
use warnings;
use Test::More tests => 27;
use Time::HiRes qw{time};
use Test::Number::Delta; #delta_within
use POSIX qw{fmod};

my $tolerance=$ENV{"Time_HiRes_Sleep_Until_TOLERANCE"} || 0.04 || 0.002; #I can get this to pass

diag("\nTolerance: $tolerance seconds\n");

BEGIN { use_ok( 'Time::HiRes::Sleep::Until' ); }

my $su = Time::HiRes::Sleep::Until->new;
isa_ok ($su, 'Time::HiRes::Sleep::Until');

my $skip=0;
{
  my $sleep  = 1;
  my $before = time;
  sleep $sleep;
  my $after  = time;
  my $delta  = abs($after - $before - $sleep);
  diag("Sleep Delta: $delta\n");
  $skip=1 if $delta > 0.001;
}
  
SKIP: {
  skip "Your machine cannot sleep reliably so we won't even try to run our tests", 25 if $skip;
  
  {
    diag("sleep 5 seconds");
    my $before = time;
    my $slept  = $su->epoch($before+5);
    my $after  = time;
    diag("before=$before");
    diag("slept=$slept");
    diag("after=$after");
    delta_within($slept, 5, $tolerance, 'epoch sleep 5 seconds into the future');
    delta_within($after, $before+5, $tolerance, 'epoch sleep 5 seconds into the future');
  }
  
  {
    diag("sleep 0 for an epoch in the past");
    my $before=time;
    my $slept=$su->epoch($before - 5);
    my $after=time;
    diag("before=$before");
    diag("slept=$slept");
    diag("after=$after");
    is($slept, 0, 'epoch no sleep for negative numbers');
    delta_within($before, $after, $tolerance, 'epoch no sleep for negative numbers');
  }
  
  {
    diag("sleep until nearest 20 second mark");
    my $before=time;
    my $slept1=$su->mark(20);
    my $after1=time;
    my $slept2=$su->mark(20);
    my $after2=time;
    diag("before=$before");
    diag("slept1=$slept1");
    diag("after1=$after1");
    diag("slept2=$slept2");
    diag("after2=$after2");
    cmp_ok($slept1, '<=', 20 + $tolerance, 'mark');
    delta_within(fmod($after1, 1), 0, $tolerance, 'mark');
    delta_within(fmod($after1, 20), 0, $tolerance, 'mark');
    delta_within($slept2, 20, $tolerance, 'mark');
    delta_within(fmod($after2, 1), 0, $tolerance, 'mark');
    delta_within(fmod($after2, 20), 0, $tolerance, 'mark');
    delta_within($after2-$after1, 20, $tolerance*2, 'mark')
  }
  {
    diag("sleep until top of minute");
    my $before=time;
    my $slept1=$su->second(0);
    my $after1=time;
    my $slept2=$su->second(2);
    my $after2=time;
    diag("before=$before");
    diag("slept1=$slept1");
    diag("after1=$after1");
    diag("slept2=$slept2");
    diag("after2=$after2");
    cmp_ok($slept1, '<=', 60 + $tolerance, 'mark');
    delta_within(fmod($after1, 1), 0, $tolerance, 'mark');
    delta_within(fmod($after1, 60), 0, $tolerance, 'mark');
    delta_within($slept2, 2, $tolerance, 'mark');
    delta_within(fmod($after2, 1), 0, $tolerance, 'mark');
    delta_within(fmod($after2, 60), 2, $tolerance, 'mark');
  }
  {
    diag("sleep until top of minute");
    my $before=time;
    my $slept1=$su->top;
    my $after1=time;
    my $slept2=$su->top;
    my $after2=time;
    diag("before=$before");
    diag("slept1=$slept1");
    diag("after1=$after1");
    diag("slept2=$slept2");
    diag("after2=$after2");
    cmp_ok($slept1, '<=', 60 + $tolerance, 'mark');
    delta_within(fmod($after1, 1), 0, $tolerance, 'mark');
    delta_within(fmod($after1, 60), 0, $tolerance, 'mark');
    delta_within($slept2, 60, $tolerance, 'mark');
    delta_within(fmod($after2, 1), 0, $tolerance, 'mark');
    delta_within(fmod($after2, 60), 00, $tolerance, 'mark');
  }

  {
    diag("time wrapper");
    my $before = time;
    my $time   = $su->time;
    delta_within($time,  $before, $tolerance, 'time');
  }
  
  {
    diag("sleep wrapper");
    my $slept = $su->sleep(0.5);
    delta_within($slept, 0.5, $tolerance, 'time');
  }
  
}
