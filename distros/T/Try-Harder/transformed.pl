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
  ;{ local $Try::Harder::TRY = sub { do {
    print "TRYING\n";
    #return "YAAY!";
    my $z =  8;
    die "EXCEPTION $z \n";
  }; return $Try::Harder::SENTINEL; };
  local $Try::Harder::CATCH = sub { do {
    print "CAUGHT: $@";
    $z = 7;
    # should return this value from the sub
    #return "YAAY!!"
  }; return $Try::Harder::SENTINEL; };
  local $Try::Harder::FINALLY = 'Try::Harder::ScopeGuard'->_new(sub {
    # should always output
    print "FINALLY, [$@]\n";
    # finally doesn't support return
    return "IMPOSSIBLE!"
  }, @_); local ( $Try::Harder::ERROR, $Try::Harder::DIED, @Try::Harder::RETVAL ); local $Try::Harder::WANTARRAY = wantarray; { local $@; $Try::Harder::DIED = not eval { if ( $Try::Harder::WANTARRAY ) { @Try::Harder::RETVAL = &$Try::Harder::TRY; } elsif ( defined $Try::Harder::WANTARRAY ) { $Try::Harder::RETVAL[0] = &$Try::Harder::TRY; } else { &$Try::Harder::TRY; } return 1; }; $Try::Harder::ERROR = $@; }; if ( $Try::Harder::DIED ) { if ( $Try::Harder::CATCH ) { local $@ = $Try::Harder::ERROR; if ( $Try::Harder::WANTARRAY ) { @Try::Harder::RETVAL = &$Try::Harder::CATCH; } elsif ( defined $Try::Harder::WANTARRAY ) { $Try::Harder::RETVAL[0] = &$Try::Harder::CATCH; } else { &$Try::Harder::CATCH; } } else { die $Try::Harder::ERROR } }; if ( caller() and (!ref($Try::Harder::RETVAL[0]) or !$Try::Harder::RETVAL[0]->isa('Try::Harder::SENTINEL')) ) { return $Try::Harder::WANTARRAY ? @Try::Harder::RETVAL : $Try::Harder::RETVAL[0]; } }
  print "\$z = $z\n";
  print "OOPS! $@\n";
  return "FAIL";
}

my $x = foo();
print "RETURNED: " . Dumper $x;

# returning from outside a sub makes no sense.
#try { print "TRYING AGAIN\n"; } #die "EXCEPTION\n" }
;{ local $Try::Harder::TRY = sub { do { print "TRYING AGAIN\n"; }; return $Try::Harder::SENTINEL; };
local $Try::Harder::CATCH = sub { do { print "CAUGHT: $@\n" }; return $Try::Harder::SENTINEL; };
local $Try::Harder::FINALLY = 'Try::Harder::ScopeGuard'->_new(sub { print "FINALLY: CAUGHT [$@]\n" }, @_); local ( $Try::Harder::ERROR, $Try::Harder::DIED, @Try::Harder::RETVAL ); local $Try::Harder::WANTARRAY = wantarray; { local $@; $Try::Harder::DIED = not eval { if ( $Try::Harder::WANTARRAY ) { @Try::Harder::RETVAL = &$Try::Harder::TRY; } elsif ( defined $Try::Harder::WANTARRAY ) { $Try::Harder::RETVAL[0] = &$Try::Harder::TRY; } else { &$Try::Harder::TRY; } return 1; }; $Try::Harder::ERROR = $@; }; if ( $Try::Harder::DIED ) { if ( $Try::Harder::CATCH ) { local $@ = $Try::Harder::ERROR; if ( $Try::Harder::WANTARRAY ) { @Try::Harder::RETVAL = &$Try::Harder::CATCH; } elsif ( defined $Try::Harder::WANTARRAY ) { $Try::Harder::RETVAL[0] = &$Try::Harder::CATCH; } else { &$Try::Harder::CATCH; } } else { die $Try::Harder::ERROR } }; if ( caller() and (!ref($Try::Harder::RETVAL[0]) or !$Try::Harder::RETVAL[0]->isa('Try::Harder::SENTINEL')) ) { return $Try::Harder::WANTARRAY ? @Try::Harder::RETVAL : $Try::Harder::RETVAL[0]; } }

print "END\n";


