#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

use Text::Pangram;

my $no_text = "The quick brown fox jumped over a lazy god.";
my $no_pangram = Text::Pangram->new($no_text);
ok( ! $no_pangram->is_pangram, 'QBF "jumped" version (no "s") not a pangram');

my $yes_text = "The quick brown fox jumps over a lazy god.";
my $yes_pangram = Text::Pangram->new($yes_text);
ok( $yes_pangram->is_pangram, 'QBF "jumps" version is a pangram');

ok( ! $no_pangram->find_pangram_window, 'FPW method fails with bad pangram');
ok( $yes_pangram->find_pangram_window, 'FPW method succeeds with good pangram');

is( $yes_pangram->window, 'The quick brown fox jumps over a lazy god', 'correct original window');
is( $yes_pangram->stripped_window, 'Thequickbrownfoxjumpsoveralazygod', 'correct stripped window');

# Numbers in text tripped up an earlier version of window regex
my $text_numbers = "The quick brown 213 fox jumps over a lazy 5,453 god.";
my $num_pangram = Text::Pangram->new($text_numbers);
ok( $num_pangram->find_pangram_window, 'FPW method succeeds with numbers in pangram');

done_testing();
