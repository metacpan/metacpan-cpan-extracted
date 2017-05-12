BEGIN {
  if (keys %INC) {
    print "1..0 # SKIP can't test categories with additional modules loaded\n";
    exit 0;
  }
}

use strict;
use warnings;

BEGIN { $ENV{PERL_STRICTURES_EXTRA} = 0 }

use strictures ();

# avoid loading Test::More, since it adds warning categories

my %known_cats; @known_cats{@strictures::WARNING_CATEGORIES} = ();
my %core_cats; @core_cats{grep ! /^(?:all|everything|extra)$/, keys %warnings::Offsets} = ();
my @missing = sort grep { !exists $known_cats{$_} } keys %core_cats;
my @extra   = sort grep { !exists $core_cats{$_} } keys %known_cats;

print "1..2\n";

print((@missing ? 'not ' : '') . "ok 1 - strictures includes all warning categories\n");
if (@missing) {
  print STDERR "# strictures is missing categories:\n";
  print STDERR "#   $_\n"
    for @missing;
}

print((@extra ? 'not ' : '') . "ok 2 - strictures includes no extra categories\n");
if (@extra) {
  print STDERR "# strictures lists extra categories:\n";
  print STDERR "#   $_\n"
    for @extra;
}

if (@missing || @extra) {
  exit 1;
}
