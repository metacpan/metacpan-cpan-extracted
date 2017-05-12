# vim:ft=perl
use Test::More tests => 4;
use_ok("Text::Ngram");
use utf8;

my $text = "абвгдеё1235678жзийклмно";
my $hash = Text::Ngram::ngram_counts($text, 3);
is_deeply($hash, {
          'абв' => 1,
          'бвг' => 1,
          'вгд' => 1,
          'где' => 1,
          'деё' => 1,
          'её ' => 1,
          ' жз' => 1,
          'жзи' => 1,
          'зий' => 1,
          'ийк' => 1,
          'йкл' => 1,
          'клм' => 1,
          'лмн' => 1,
          'мно' => 1,
         }, "Simple test finds all ngrams");
Text::Ngram::add_to_counts("абв", 3, $hash);
is($hash->{"абв"}, 2, "Simple incremental adding works");
is($hash->{"бвг"}, 1, "Without messing everything else up");
