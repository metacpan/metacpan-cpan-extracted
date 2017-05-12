use strict;
use warnings;
use Test::More tests => 7 + ($] < 5.013001 ? 1 : 0);
use Test::Fatal qw(exception success);
use Try::Tiny 0.07;

like(
  exception { die "foo bar" },
  qr{foo bar},
  "foo bar is like foo bar",
);

ok(
  ! exception { 1 },
  "no fatality means no exception",
);

try {
  die "die";
} catch {
  pass("we die on demand");
} success {
  fail("this should never be emitted");
};

try {
  # die "die";
} catch {
  fail("we did not demand to die");
} success {
  pass("a success block runs, passing");
};

{
    my $i = 0;
    try {
        die { foo => 42 };
    } catch {
        1;
    } success {
        fail("never get here");
    } finally {
        $i++;
        pass("finally block after success block");
    };

    is($i, 1, "finally block after success block still runs");
};

# TODO: test for fatality of undef exception?

{
  package BreakException;
  sub DESTROY { eval { my $x = 'o no'; } }
}

if ($] < 5.013001) {
  like(
    exception { exception {
      my $blackguard = bless {}, 'BreakException';
      die "real exception";
    } },
    qr{false exception},
    "we throw a new exception if the exception is false",
  );
}

{
  package FalseObject;
  use overload 'bool' => sub { 0 };
}

like(
  exception { exception { die(bless {} => 'FalseObject'); } },
  qr{false exception},
  "we throw a new exception if the exception is false",
);
