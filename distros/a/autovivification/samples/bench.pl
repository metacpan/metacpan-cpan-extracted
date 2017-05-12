#!perl

use strict;
use warnings;

use Benchmark qw<:hireswallclock cmpthese>;

use blib;

my $count = -1;

my @tests;

{
 my %h = ();

 push @tests, [
  'Fetch a non-existing key from a hash',
  {
   av   => sub { $h{a} },
   noav => sub { no autovivification; $h{a} },
  }
 ];
}

{
 my %h = (a => 1);

 push @tests, [
  'Fetch an existing key from a hash',
  {
   av   => sub { $h{a} },
   noav => sub { no autovivification; $h{a} },
  }
 ];
}

{
 my $x = { };

 push @tests, [
  'Fetch a non-existing key from a hash reference',
  {
   av          => sub { $x->{a} },
   noav        => sub { no autovivification; $x->{a} },
   noav_manual => sub { defined $x ? $x->{a} : undef },
  }
 ];
}

{
 my $x = { a => 1 };

 push @tests, [
  'Fetch an existing key from a hash reference',
  {
   av          => sub { $x->{a} },
   noav        => sub { no autovivification; $x->{a} },
   noav_manual => sub { defined $x ? $x->{a} : undef },
  }
 ];
}

{
 my $x = { a => { b => { c => { d => 1 } } } };

 push @tests, [
  'Fetch a 4-levels deep existing key from a hash reference',
  {
   av          => sub { $x->{a}{b}{c}{d} },
   noav        => sub { no autovivification; $x->{a}{b}{c}{d} },
   noav_manual => sub { my $z; defined $x ? ($z = $x->{a}, defined $z ? ($z = $z->{b}, defined $z ? ($z = $z->{c}, defined $z ? $z->{d} : undef) : undef) : undef) : undef },
  }
 ];
}

{
 my $x = { };
 $x->{$_} = undef       for 100 .. 199;
 $x->{$_} = { $_ => 1 } for 200 .. 299;
 my $n = 0;

 no warnings 'void';

 push @tests, [
  'Fetch 2-levels deep existing or non-existing keys from a hash reference',
  {
   inc         => sub { $n = ($n+1) % 300 },
   av          => sub { $x->{$n}{$n}; $n = ($n+1) % 300 },
   noav        => sub { no autovivification; $x->{$n}{$n}; $n = ($n+1) % 300 },
   noav_manual => sub { my $z; defined $x ? ($z = $x->{a}, (defined $z ? $z->{b} : undef)) : undef; $n = ($n + 1) % 300 },
  }
 ];
}

for my $t (@tests) {
 printf "--- %s ---\n", $t->[0];
 cmpthese $count, $t->[1];
 print "\n";
}
