#!perl
use 5.006;
use strict;
use warnings;
use Test::More;
use Config;
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

    $out .= $@ if $@;

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

# Storable's deep clone.
{
    my $arr1 = [ 1 .. 3 ];
    my $arr2 = clone $arr1;
    $arr2->[0] = 111;

    is_deeply
      $arr1,
      [ 1, 2, 3 ],
      "clone - original array";

    is_deeply
      $arr2,
      [ 111, 2, 3 ],
      "clone - cloned array";
}

# UTF-8.
is
  enc( "\x{5D0}" ),
  "\x{D7}\x{90}",
  "enc - alef code to bytes";

is length "\x{5D0}", 1, "enc - single char";

is
  enc( "\N{HEBREW LETTER ALEF}" ),
  "\x{D7}\x{90}",
  "enc - alef name to bytes";

is
  dec( "\x{D7}\x{90}" ),
  "\x{5D0}",
  "dec - bytes to alef code";

is length "\x{D7}\x{90}", 2, "dec - 2 bytes ";

is
  dec( enc( "\x{5D0}" ) ),
  "\x{5D0}",
  "enc,dec - same value";

is
  enc( dec( "\x{D7}\x{90}" ) ),
  "\x{D7}\x{90}",
  "dec,enc - same value";

is scalar enc( "\x{5D0}" ) =~ /\w/, "", "enc - not word";

is scalar dec( "\x{D7}\x{90}" ) =~ /\w/, 1, "dec - is word";

my $is_wide_warning = qr{ \b in \s+ say \s+ at \b }x;

unlike
  run( sub { say dec "\x{D7}\x{90}" } ),
  $is_wide_warning,
  "dec - no wide char warning";

unlike
  run( sub { say "\x{5D0}" } ),
  $is_wide_warning,
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

# Set - Unique.
is
  run( sub { print set( 2, 4, 6, 4 ) } ),
  "(2 4 6)",
  "set unique";

# Clear a new universe to not interfere with above.
Set::Scalar::Universe->new->enter;

# Set Object.
my $a = set( qw( a b c d e ) );
my $b = set( qw( c d e f g ) );
my $c = set( qw( e f g h i ) );

# Set - Union.
is
  run( sub { print $a + $b } ),
  "(a b c d e f g)",
  "set union: a + b";
is
  run( sub { print $a + $b + $c } ),
  "(a b c d e f g h i)",
  "set union: a + b + c";

# Set - Intersection.
is
  run( sub { print $a * $b } ),
  "(c d e)",
  "set intersection: a * b";
is
  run( sub { print $a * $b * $c } ),
  "(e)",
  "set intersection: a * b * c";

# Set - Difference.
is
  run( sub { print $a - $b } ),
  "(a b)",
  "set difference: a - b";
is
  run( sub { print $a - $b - $c } ),
  "(a b)",
  "set difference: a - b - c";

# Set - Symmetric Difference.
is
  run( sub { print $a % $b } ),
  "(a b f g)",
  "set symmetric difference: a % b";
is
  run( sub { print $a % $b % $c } ),
  "(a b e h i)",
  "set symmetric difference: a % b % c";

# Set - Unique.
is
  run( sub { print $a / $b } ),
  "(a b f g)",
  "set unique: a / b";
is
  run( sub { print $a / $b / $c } ),
  "(a b e h i)",
  "set unique: a / b / c";

# Set - Complement.
is
  run( sub { print -$a } ),
  "(f g h i)",
  "set complement: -a";
is
  run( sub { print -$b } ),
  "(a b h i)",
  "set complement: -b";


######################################
#         Files Convenience
######################################

# File Object.
is
  f( "/proc/cpuinfo" )->basename,
  "cpuinfo",
  "f - basename";

######################################
#            Math Help
######################################

is
    max(10,20,9,15),
    20,
    "max - sanity check";

is
    min(10,20,9,15),
    9,
    "min - sanity check";

######################################
#             Output
######################################

# Say
is
  run( sub { say 11 } ),
  "11\n",
  "say - scalar";

is
  run( sub { say 11, 22 } ),
  "1122\n",
  "say - array";

is
  run( sub { say for 1, 2, 3 } ),
  "1\n2\n3\n",
  "say - void (default var)";

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
#           Asynchronous
######################################

{
    my @actions =
      map {
        my $num = $_;
        sub { ( $num => "Got $num" ) };
      } 1 .. 3;
    my %expected = map { $_->() } @actions;

    is_deeply { runio @actions }, \%expected, "runio - simple return";

    is_deeply { runf @actions }, \%expected, "runf - simple return";

    if ( $Config{useithreads} ) {
        is_deeply { runt @actions }, \%expected, "runt - simple return";
    }
    else {
        pass "[SKIPPED - threading not supported] runt - simple return";
    }
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
