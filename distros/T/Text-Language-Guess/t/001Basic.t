######################################################################
# Test suite for Text::Language::Guess
# by Mike Schilli <cpan@perlmeister.com>
######################################################################

use warnings;
use strict;

use Test::More tests => 11;
BEGIN { use_ok('Text::Language::Guess') };

my $canned = "canned";
$canned = "t/canned" unless -d $canned;

######################################################################
# file versions
######################################################################
my $guesser = Text::Language::Guess->new();
is($guesser->language_guess("$canned/de.txt"), 'de', "Guess German");
is($guesser->language_guess("$canned/en.txt"), 'en', "Guess English");

######################################################################
# string versions
######################################################################
my $data = Text::Language::Guess::slurp("$canned/de.txt");
is($guesser->language_guess_string($data), 'de', "Guess German");

$data = Text::Language::Guess::slurp("$canned/en.txt");
is($guesser->language_guess_string($data), 'en', "Guess English");

######################################################################
# scores
######################################################################
my $scores = $guesser->scores("$canned/de.txt");
ok(exists $scores->{de}, "de in score table");

$scores = $guesser->scores("$canned/en.txt");
ok(exists $scores->{en}, "en in score table");

    # string versions
$data = Text::Language::Guess::slurp("$canned/de.txt");
$scores = $guesser->scores_string($data);
ok(exists $scores->{de}, "de in score table");

$data = Text::Language::Guess::slurp("$canned/en.txt");
$scores = $guesser->scores_string($data);
ok(exists $scores->{en}, "en in score table");

######################################################################
# limited choices
######################################################################
$guesser = Text::Language::Guess->new(languages => ['da', 'nl']);
like($guesser->language_guess("$canned/de.txt"), qr/da|nl/,
        "Limited choice");
like($guesser->language_guess("$canned/en.txt"), qr/da|nl/,
        "Limited choice");

