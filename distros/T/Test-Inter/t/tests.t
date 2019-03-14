#!/usr/bin/perl

use warnings 'all';
use strict;
BEGIN {
   if (-d "lib") {
      use lib "./lib";
   } elsif (-d "../lib") {
      use lib "../lib";
   }
}

use Test::Inter;
my $ti = new Test::Inter $0;

sub func {
  my(@args) = @_;
  my @ret;
  foreach my $arg (@args) {
     push(@ret,length($arg));
  }
  return @ret;
}

$ti->tests(func  => \&func,
          tests => "foo        => 3

                    a ab       => 1 2

                    (x xy xyz) => 1 2 3

                    (a) (bc)   => 1 2

                    (a (b cd)) => 1 1 2

                    (,a,bc)    => 1 2

                    (,a,b c)   => 1 3
                   ");

$ti->tests(func     => \&func,
          expected => [ [1,2] ],
          tests    => "a ab

                       c cd

                       e ef
                      ");

$ti->tests(func     => \&func,
          expected => "1 2",
          tests    => "a ab

                       c cd

                       e ef
                      ");

$ti->tests(tests    => " '' ''

                        [] []

                        {} {}
                      ");

$ti->done_testing();
