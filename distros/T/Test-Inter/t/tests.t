#!/usr/bin/perl

use Test::Inter;
$o = new Test::Inter;

sub func {
  my(@args) = @_;
  my @ret;
  foreach my $arg (@args) {
     push(@ret,length($arg));
  }
  return @ret;
}

$o->tests(func  => \&func,
          tests => "foo        => 3

                    a ab       => 1 2

                    (x xy xyz) => 1 2 3

                    (a) (bc)   => 1 2

                    (a (b cd)) => 1 1 2

                    (,a,bc)    => 1 2

                    (,a,b c)   => 1 3
                   ");

$o->tests(func     => \&func,
          expected => [ [1,2] ],
          tests    => "a ab

                       c cd

                       e ef
                      ");

$o->tests(func     => \&func,
          expected => "1 2",
          tests    => "a ab

                       c cd

                       e ef
                      ");

$o->tests(tests    => "1

                       '' ''
                      ");

$o->done_testing();
