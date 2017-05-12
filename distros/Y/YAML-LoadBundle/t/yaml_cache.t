use 5.10.0;
use strict;
use warnings;

BEGIN { $ENV{YAML_LOADBUNDLE_CACHEDIR} = 'TestCacheDir' }

use YAML::LoadBundle  qw( load_yaml load_yaml_bundle );
use Time::HiRes qw(time);
use File::Temp qw( tempdir );
use Test::More  tests => 20;

sub sum { my $n = 0; $n += $_ for @_; return $n }

# These gin up a simple YAML string.
sub yaml_kv
{
    my $n = shift;
    map { "K$_: $_" } 1..$n
}

sub yaml_kk
{
    my($lines, $n) = @_;
    map { ("K$_:", map { "  " . $_ } @$lines) } 1..$n
}

# Recusively returns all values from nested hashes
sub deep_values
{
    my $h = shift;
    map { ref($_) ? deep_values($_) : $_ } values %$h;
}

is $YAML::LoadBundle::CacheDir, 'TestCacheDir',
    "Correct cache dir from ENV";

$YAML::LoadBundle::CacheDir = undef;

my @lines    = yaml_kv(10);
my $expected = 55;           # True for our YAML strings

my $cache_dir = tempdir( "load_yaml-XXXXXXXXX", CLEANUP => 1 ) . '/yaml_cache';
$YAML::LoadBundle::CacheDir = $cache_dir;

for (1..4)
{
       @lines  = yaml_kk(\@lines, 10);
    my $yaml   = join "\n", @lines;
    my $size   = length $yaml;

    my $t0     = time;
    my $yaml_1 = load_yaml($yaml);
    my $t1     = time;
    my $yaml_2 = load_yaml($yaml);
    my $t2     = time;

    # Quick 'n' dirty hack to check that our struct looks like it ought.
    # To do a complete check, we would need...a YAML parser...
    $expected *= 10;
    cmp_ok((sum deep_values($yaml_1)), '==', $expected, "initial sum values is $expected");
    cmp_ok((sum deep_values($yaml_2)), '==', $expected, "cached  sum values is $expected");

    my $dt1    = $t1 - $t0;
    my $dt2    = $t2 - $t1;
    my $factor = int($dt1 / $dt2);

    # Typical speedup is ~ 100x.
    # But we can't reliably test for speedup, because we aren't on a hard real-time system.
    # So we just check that we get the same thing both times, and print the speedup as informational.
    is_deeply($yaml_2, $yaml_1, sprintf "YAML %7d bytes; cache is %3dx faster", $size, $factor);
}

ok load_yaml( 't/yaml_dir/books/advanced_perl_programming.yml', 1 ),
    "Load file without caching";
ok((not -e $cache_dir), "We didn't cache anything to disk");

ok load_yaml('t/yaml_dir/books/advanced_perl_programming.yml'),
    "Load file with caching";
ok( -e $cache_dir, "Now we've cached something" );

my @got = glob("$cache_dir/*");
my $expect = 1;
is @got, $expect, "Cached something";

ok load_yaml_bundle('t/yaml_dir'), "Loaded bundle with caching";
$expect = 2;
@got = glob("$cache_dir/*");
is @got, $expect, "Cached somethign else";
