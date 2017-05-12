#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 1;

sub extract_more_from {
  return;
}
sub some_condition {
  return 0;
}


#------------------------------------------------------------------------------

 use Test::Weaken qw(leaks);
 my $leaks = leaks(sub {
                    my $obj = { one => 1,
                                two => [],
                                three => [3,3,3] };
                    return $obj;
                   });
 if ($leaks) {
     print "There were memory leaks from test 1!\n";
     printf "%d of %d original references were not freed\n",
         $leaks->unfreed_count(), $leaks->probe_count();
 } else {
     print "No leaks in test 1\n";
 }

 $leaks = Test::Weaken::leaks(
    { constructor => sub {
        my @array = (42, 711);
        push @array, \@array;  # circular reference
        return \@array;
      },
      destructor  => sub {
        print "This could invoke an object destructor\n";
      },
      ignore  => sub {
        my ($ref) = @_;
        if (some_condition($ref)) {
          return 1;  # ignore
        }
        return 0; # don't ignore
      },
      contents  => sub {
        my ($ref) = @_;
        return extract_more_from($ref);
      },
    });
 if ($leaks) {
     print "There were memory leaks from test 2!\n";
     my $unfreed_proberefs = $leaks->unfreed_proberefs();
     print "These are the probe references to the unfreed objects:\n";
     require Data::Dumper;
     foreach my $ref (@$unfreed_proberefs) {
         print "ref $ref\n";
         print Data::Dumper->Dump([$ref], ['unfreed']);
     }
 }

#------------------------------------------------------------------------------

ok(1);
exit 0;
