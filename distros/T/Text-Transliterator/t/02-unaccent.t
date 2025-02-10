use Test::More;
use utf8;
use strict;
use warnings;

use Text::Transliterator::Unaccent;

my $want_benchmarks 
  = $ENV{BENCHMARK_TESTS} 
  && eval "use Text::Unaccent; use Text::StripAccents; use Time::HiRes; 1";

my $string = "il était une bergère";
my $tr = Text::Transliterator::Unaccent->new;

$tr->(my $copy = $string);
is $copy, "il etait une bergere", "basic test";


$tr = Text::Transliterator::Unaccent->new(modifiers => 'r');

my @results = $tr->(  "la belle hétaïre", "était sans vêtements");
is_deeply \@results, ["la belle hetaire", "etait sans vetements"], "with 'r' modifier";


if ($want_benchmarks) {
  my $latin_ranges    = Unicode::UCD::charscript('Latin');
  my $all_latin_chars = pack "U*", map {$_->[0] .. $_->[1]} @$latin_ranges;
  my ($t0, $t1, @strings, %timings);
  my $n_concat  = 50;
  my $n_strings = 10;

  @strings = ($all_latin_chars x $n_concat) x $n_strings;
  $t0 = Time::HiRes::time();
  $tr->($_) foreach @strings;
  $t1 = Time::HiRes::time();
  $timings{'Text::Transliterator::Unaccent'} = $t1 - $t0;

  @strings = ($all_latin_chars x $n_concat) x $n_strings;
  $t0 = Time::HiRes::time();
  @strings = map {unac_string('UTF-8', $_)} @strings;
  $t1 = Time::HiRes::time();
  $timings{'Text::Unaccent'} = $t1 - $t0;

  @strings = ($all_latin_chars x $n_concat) x $n_strings;
  $t0 = Time::HiRes::time();
  stripaccents($_) foreach @strings;
  $t1 = Time::HiRes::time();
  $timings{'Text::StripAccents'} = $t1 - $t0;

  # ok($timings{'Text::Transliterator::Unaccent'} < $timings{'Text::Unaccent'});
  ok($timings{'Text::Transliterator::Unaccent'} < $timings{'Text::StripAccents'});
  diag("timing for $_ is $timings{$_}") for keys %timings;
}


done_testing;
