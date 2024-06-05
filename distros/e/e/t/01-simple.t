#!perl
use 5.006;
use strict;
use warnings;
use Test::More;
use e;

sub run {
    my $out = "";

    {
        local *STDOUT;
        local *STDERR;
        open STDOUT, ">",  \$out or die $!;
        open STDERR, ">>", \$out or die $!;
        eval { shift->() };
    }

    $out;
}

is b( "abc" )->size, 3, "b - size";

is_deeply
  c( 1, 2, 1, 3 )->uniq->to_array,
  [ 1, 2, 3 ],
  "c - uniq";

is
  f( "/proc/cpuinfo" )->basename,
  "cpuinfo",
  "f - basename";

is
  j( { a => 1 } ),
  q({"a":1}),
  "j - ref to json string";

is_deeply
  j( q({"a":1}) ),
  { a => 1 },
  "j - json string to ref";

monkey_patch( "A", func => sub { 111 } );
is
  A::func(),
  111,
  "monkey_patch - simple example";

like run(
    sub {
        n sub { }
    }
  ),
  qr{ ^ test \s+ \d+ }xm,
  "n - sanity check (single)";

like run(
    sub {
        n sub { }, 10;
    }
  ),
  qr{ ^ test \s+ \d+ }xm,
  "n - sanity check (single,times)";

like run(
    sub {
        n { a => sub { }, b => sub { } };
    }
  ),
  qr{ ^ [ab] \s+ \d+ .+ \n [ab] \s+ \d+ }xm,
  "n - sanity check (multiple)";

like run(
    sub {
        n { a => sub { }, b => sub { } }, 10;
    }
  ),
  qr{ ^ [ab] \s+ \d+ .+ \n [ab] \s+ \d+ }xm,
  "n - sanity check (multiple,times)";

is
  x ( "<h1>title</h1>" )->at( "h1" )->text,
  "title",
  "x - at, text";

is
  yml( { a => 1 } ),
  "---\na: 1\n",
  "yml - ref to yml string";

is_deeply
  yml( "---\na: 1" ),
  { a => 1 },
  "yml - yml string to ref";

done_testing();
