#!/usr/bin/env perl
use 5.020;
use strict;
use warnings;
use lib 'lib';

use Wordsmith::Claude qw(question);
use IO::Async::Loop;

my $loop = IO::Async::Loop->new;

# Example 1: Ask a question about text
my $essay = <<'TEXT';
The Industrial Revolution, which began in Britain in the late 18th century,
fundamentally transformed human society. It marked the transition from
agrarian economies to industrial manufacturing. Key innovations like the
steam engine, spinning jenny, and power loom mechanized production and
increased efficiency dramatically. This period also saw significant social
changes, including urbanization, the rise of the factory system, and new
labor movements. The effects of the Industrial Revolution continue to
shape our world today.
TEXT

say "=== Question about text ===";
say "Text: (essay about Industrial Revolution)";
say "";

my $answer = question(
    text     => $essay,
    question => "What were the key innovations mentioned?",
    loop     => $loop,
)->get;

say "Q: What were the key innovations mentioned?";
say "A: " . $answer->text;
say "";

# Example 2: Ask about main argument
$answer = question(
    text     => $essay,
    question => "In one sentence, what is the main point?",
    loop     => $loop,
)->get;

say "Q: In one sentence, what is the main point?";
say "A: " . $answer->text;
say "";

# Example 3: General question (no context)
say "=== General questions (no context) ===";
say "";

$answer = question(
    question => "What is the capital of France?",
    loop     => $loop,
)->get;

say "Q: What is the capital of France?";
say "A: " . $answer->text;
say "";

$answer = question(
    question => "Explain quantum entanglement in one sentence.",
    loop     => $loop,
)->get;

say "Q: Explain quantum entanglement in one sentence.";
say "A: " . $answer->text;
