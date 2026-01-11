#!/usr/bin/env perl
#
# Parallel requests example - run multiple rewrites concurrently
#
use 5.020;
use strict;
use warnings;
use utf8;
use open ':std', ':encoding(UTF-8)';
use lib 'lib', '../lib';

use Wordsmith::Claude qw(rewrite question);
use IO::Async::Loop;
use Future;

my $loop = IO::Async::Loop->new;

my $text = "The software update includes several bug fixes and performance improvements.";

say "Original: $text\n";
say "Running 4 parallel requests...\n";

# Start all requests at once (non-blocking)
my $f_eli5   = rewrite(text => $text, mode => 'eli5',   loop => $loop);
my $f_formal = rewrite(text => $text, mode => 'formal', loop => $loop);
my $f_pirate = rewrite(text => $text, mode => 'pirate', loop => $loop);
my $f_question = question(
    text     => $text,
    question => "Is this good news or bad news?",
    loop     => $loop,
);

# Wait for all to complete
my @results = Future->needs_all($f_eli5, $f_formal, $f_pirate, $f_question)->get;

say "ELI5:";
say "  ", $results[0]->text, "\n";

say "Formal:";
say "  ", $results[1]->text, "\n";

say "Pirate:";
say "  ", $results[2]->text, "\n";

say "Question (Is this good or bad news?):";
say "  ", $results[3]->text, "\n";

# Example with batch processing
say "=" x 60;
say "Batch processing multiple texts in parallel:\n";

my @texts = (
    "I'm really angry about this situation.",
    "The meeting was boring.",
    "We need to synergize our core competencies.",
);

my @futures = map {
    rewrite(text => $_, mode => 'friendly', loop => $loop)
} @texts;

my @friendly = Future->needs_all(@futures)->get;

for my $i (0..$#texts) {
    say "Original: $texts[$i]";
    say "Friendly: ", $friendly[$i]->text;
    say "";
}
