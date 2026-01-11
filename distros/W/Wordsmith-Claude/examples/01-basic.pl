#!/usr/bin/env perl
#
# Basic rewriting example
#
use strict;
use warnings;
use lib 'lib', '../lib';

use Wordsmith::Claude qw(rewrite);
use IO::Async::Loop;

my $loop = IO::Async::Loop->new;

my $complex_text = <<'TEXT';
The implementation of quantum error correction protocols necessitates
the utilization of redundant qubit encoding schemes to mitigate the
deleterious effects of decoherence and operational imperfections
inherent in contemporary quantum computing architectures.
TEXT

print "Original:\n$complex_text\n";
print "=" x 60, "\n";

# ELI5 - Explain Like I'm 5
print "\nELI5:\n";
my $result = rewrite(
    text => $complex_text,
    mode => 'eli5',
    loop => $loop,
)->get;
print $result->text, "\n";

print "=" x 60, "\n";

# Casual tone
print "\nCasual:\n";
$result = rewrite(
    text => $complex_text,
    mode => 'casual',
    loop => $loop,
)->get;
print $result->text, "\n";

print "=" x 60, "\n";

# Pirate!
print "\nPirate:\n";
$result = rewrite(
    text => $complex_text,
    mode => 'pirate',
    loop => $loop,
)->get;
print $result->text, "\n";
