#!/usr/bin/perl -w
use strict;
use warnings;
use Unicode::SetAutomaton;
use Set::IntSpan;
use Set::IntSpan::Fast;

warn "Reading code points in HHHH notation from STDIN (one per line)\n";

chomp(@_ = <>);

# Set::IntSpan is rather slow building the set, so use this instead
my $fast = Set::IntSpan::Fast->new(map hex, @_);

# Then of course Set::IntSpan and Set::IntSpan::Fast do not really
# have compatible APIs, so we have to convert and rebuild the set.
my $set = Set::IntSpan->new($fast->as_string);

my $dfa = Unicode::SetAutomaton->new(classes => [$set]);

print $dfa->as_expressions;
