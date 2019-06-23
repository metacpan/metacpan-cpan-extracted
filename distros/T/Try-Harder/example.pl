#!/usr/bin/env perl
#
# To get the filtered code, try this:
#  perl -c -MFilter::ExtractSource test.pl | grep -v '^use Try::Harder;'
#
use strict;
use warnings;
use lib './lib';
use Try::Harder;
use Data::Dumper;

print "BEGIN\n";

sub foo {
  my $z = 1;
  try {
    print "TRYING\n";
    #return "YAAY!";
    my $z =  8;
    die "EXCEPTION $z \n";
  }
  catch {
    print "CAUGHT: $@";
    $z = 7;
    # should return this value from the sub
    #return "YAAY!!"
  }
  finally {
    # should always output
    print "FINALLY, [$@]\n";
    # finally doesn't support return
    return "IMPOSSIBLE!"
  }
  print "\$z = $z\n";
  print "OOPS! $@\n";
  return "FAIL";
}

my $x = foo();
print "RETURNED: " . Dumper $x;

# returning from outside a sub makes no sense.
#try { print "TRYING AGAIN\n"; } #die "EXCEPTION\n" }
try { print "TRYING AGAIN\n"; }
catch { print "CAUGHT: $@\n" }
finally { print "FINALLY: CAUGHT [$@]\n" }

print "END\n";


