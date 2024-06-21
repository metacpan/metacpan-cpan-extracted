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
        utf8;
        eval { shift->() };
    }

    $out;
}

######################################
#          Investigation
######################################

# Benchmark/timing.
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

######################################
#         Format Conversions
######################################

# Json.
is
  j( { a => 1 } ),
  q({"a":1}),
  "j - ref to json string";

is_deeply
  j( q({"a":1}) ),
  { a => 1 },
  "j - json string to ref";

# XML/HTML.
is
  x ( "<h1>title</h1>" )->at( "h1" )->text,
  "title",
  "x - at, text";

# YAML.
is
  yml( { a => 1 } ),
  "---\na: 1\n",
  "yml - ref to yml string";

is_deeply
  yml( "---\na: 1" ),
  { a => 1 },
  "yml - yml string to ref";

# UTF-8.
is
  enc( "\x{5D0}" ),
  "\x{D7}\x{90}",
  "enc - alef code to bytes";

is
  enc( "\N{HEBREW LETTER ALEF}" ),
  "\x{D7}\x{90}",
  "enc - alef name to bytes";

is
  dec( "\x{D7}\x{90}" ),
  "\x{5D0}",
  "dec - bytes to alef code";

is
  dec( enc( "\x{5D0}" ) ),
  "\x{5D0}",
  "enc,dec - same value";

is
  enc( dec( "\x{D7}\x{90}" ) ),
  "\x{D7}\x{90}",
  "dec,enc - same value";

is
  scalar enc( "\x{5D0}" ) =~ /\w/, "",
  "enc - not word";

is
  scalar dec( "\x{D7}\x{90}" ) =~ /\w/, 1,
  "dec - is word";

is
    length(run( sub{ say dec "\x{D7}\x{90}" } )),
    3,
    "dec - no wide char warning";

is
    length(run( sub{ say "\x{5D0}" } )),
    3,
    "dec - no wide char warning";

######################################
#          Enhanced Types
######################################

# String Object.
is b( "abc" )->size, 3, "b - size";

# Array Object.
is_deeply
  c( 1, 2, 1, 3 )->uniq->to_array,
  [ 1, 2, 3 ],
  "c - uniq";

######################################
#         Files Convenience
######################################

# File Object.
is
  f( "/proc/cpuinfo" )->basename,
  "cpuinfo",
  "f - basename";

######################################
#             Output
######################################

# Table
{
    my @lines    = ( [qw(key value)], [qw(red 111)], [qw(blue 222)] );
    my @expected = (
        "+------+-------+", "| key  | value |",
        "+------+-------+", "| red  | 111   |",
        "| blue | 222   |", "+------+-------+",
    );

    my @list = table( @lines );
    is_deeply \@list, \@expected, "table - list context";

    my $scalar = table( @lines );
    is
      $scalar,
      join( "\n", @expected ),
      "table - scalar context";

    is
      run( sub { table( @lines ) } ),
      join( "", map { "$_\n" } @expected ),
      "table - void context";

}

######################################
#         Package Building
######################################

monkey_patch( "A", func => sub { 111 } );
is
  A::func(),
  111,
  "monkey_patch - simple example";

done_testing();
