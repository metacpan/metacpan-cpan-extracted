#!/usr/bin/env perl
#
# Custom instruction example
#
use strict;
use warnings;
use utf8;
use open ':std', ':encoding(UTF-8)';
use lib 'lib', '../lib';

use Wordsmith::Claude qw(rewrite);
use IO::Async::Loop;

my $loop = IO::Async::Loop->new;

my $text = "The software update includes several bug fixes and performance improvements.";

print "Original: $text\n\n";

# Nature documentary narrator
print "As a nature documentary narrator:\n";
my $result = rewrite(
    text        => $text,
    instruction => "Rewrite this as David Attenborough narrating a nature documentary. Be dramatic and reverent.",
    loop        => $loop,
)->get;
print "  ", $result->text, "\n\n";

# Sports announcer
print "As a sports announcer:\n";
$result = rewrite(
    text        => $text,
    instruction => "Rewrite this as an excited sports announcer calling a big play. Be energetic!",
    loop        => $loop,
)->get;
print "  ", $result->text, "\n\n";

# Haiku
print "As a haiku:\n";
$result = rewrite(
    text        => $text,
    instruction => "Rewrite this as a haiku (5-7-5 syllable structure).",
    loop        => $loop,
)->get;
print "  ", $result->text, "\n\n";

# Movie trailer voice
print "As a movie trailer:\n";
$result = rewrite(
    text        => $text,
    instruction => "Rewrite this as an epic movie trailer voiceover. Dramatic. Intense. Use short punchy sentences.",
    loop        => $loop,
)->get;
print "  ", $result->text, "\n";
