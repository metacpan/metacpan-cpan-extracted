#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 18;
use lib grep { -d $_ } qw(./lib ../lib);
use Test::Easy::DataDriven qw(run_where);

# toss an error if your left-arg isn't a scalar ref
{
  my $foo = 'dilation-compliant';

  my $error = do {
    local $@;

    eval {
      run_where(
        [$foo => 'aargh I shoulda provided \$foo, not $foo, to the left of that =>!'],
        sub {
          ok( 0, "didn't expect to hit this..." );
        }
       );
    };

    $@;
  };

  like(
    $error,
    qr{error: you gave me a bare scalar - give me a scalar reference instead at.*?Test/Easy/DataDriven.pm line \d+.*eval \{\.\.\.\} called at.*? line \d+}sm,
    'Asserted with a somewhat-helpful stacktrace on weird args'
  );
}

{
  my $foo = 'foo value';
  my $bar = sub { uc(shift()) };
  is( $foo, 'foo value', 'sanity test: $foo has correct default value' );
  is( $bar->($foo), 'FOO VALUE', 'sanity test: $bar upper-cases its args' );

  run_where(
    [\$foo => 'some different value'],
    [\$bar => sub { my $val = shift; $val =~ tr/aeiou//d; $val }],
    sub {
      is( $bar->($foo), 'sm dffrnt vl', '$foo and $bar swapped out' );
    },
   );

  is( $foo, 'foo value', '$foo is restored to its original value' );
  is( ref($bar), 'CODE', '$bar is still a code ref' );
  is( $bar->($foo), 'FOO VALUE', '$bar is restored to its original value' );
}


{
  my ($foo, $bar, $baz) = (1, sub { 2 }, [3]);

  # sanity tests
  is( $foo, 1, '$foo is sane' );
  is( $bar->(), 2, '$bar is sane' );
  is_deeply( $baz, [3], '$baz is sane' );

  # we can specify new values for variables for a testing sub and
  # expect the testing sub to see those values
  run_where(
    [\$foo => 'foo'],
    [\$bar => sub { 'bar' }],
    [\$baz => [8,9]],
    sub {
      is( $foo, 'foo', '$foo has temp value' );
      is( $bar->(), 'bar', '$bar has temp value' );
      is_deeply( $baz, [8,9], '$baz has temp value' );
    }
   );

  # rollback the variables to their original values
  is( $foo, 1, '$foo restored' );
  is( $bar->(), 2, '$bar restored' );
  is_deeply( $baz, [3], '$baz restored' );
}

# the return value of run_where is the same as your testing sub's return value,
# with context awareness etc.
{
  my $context_sensitive = sub { wantarray ? 'array' : 'scalar or void' };

  my $out = run_where($context_sensitive);
  is( $out, 'scalar or void', 'detected scalar/void context properly' );

  ($out) = run_where($context_sensitive);
  is( $out, 'array', 'detected array context properly' );
}
