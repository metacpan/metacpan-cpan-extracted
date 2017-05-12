#!perl

use latest;

use Test::More tests => 3;

eval '$some_global = 1';

like $@, qr{requires explicit package name}, 'strict';

SKIP: {
  skip 'Need Perl 5.10' => 2 if $] < 5.010;
  my $out;
  {
    local *STDOUT;
    open STDOUT, '>', \$out;
    eval 'say "Foo"';
  }
  ok !$@, 'say compiles' or diag $@;
  is $out, "Foo\n", 'say works';
}

# vim:ts=2:sw=2:et:ft=perl

