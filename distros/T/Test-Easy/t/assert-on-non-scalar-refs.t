#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 1;
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
