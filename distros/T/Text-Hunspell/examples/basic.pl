#!/usr/bin/env perl
#
# Basic tests of Text::Hunspell
# Taken from the main POD documentation.
#
# For this example to work, you have to have
# the US english dictionary installed!
#
# On Debian/Ubuntu systems, it should be
# enough to type:
#
#   sudo apt-get install hunspell libhunspell-dev
#
# Have fun!
#
# Cosimo, 06/Sep/2010
#

use strict;
use warnings;
use Text::Hunspell;

# You can use relative or absolute paths.
my $speller = Text::Hunspell->new(
    "/usr/share/hunspell/en_US.aff",    # Hunspell affix file
    "/usr/share/hunspell/en_US.dic"     # Hunspell dictionary file
);

die unless $speller;

# Check a word against the dictionary
my $word = 'opera';
print $speller->check($word)
      ? "'$word' found in the dictionary\n"
      : "'$word' not found in the dictionary!\n";

# Spell check suggestions
my $misspelled = 'programmng';
my @suggestions = $speller->suggest($misspelled);
print "\n", "You typed '$misspelled'. Did you mean?\n";
for (@suggestions) {
    print "  - $_\n";
}

# Analysis of a word
$word = 'automatic';
my $analysis = $speller->analyze($word);
print "\n", "Analysis of '$word' returns '$analysis'\n";

# Word stemming
$word = 'development';
my @stemming = $speller->stem($word);
print "\n", "Stemming of '$word' returns:\n";
for (@stemming) {
    print "  - $_\n";
}

