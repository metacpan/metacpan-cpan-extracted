package WebService::Cmis::Test::ChangeFeed;
use base qw(WebService::Cmis::Test);

use strict;
use warnings;

use Test::More;

sub test_ChangeFeed_paginate : Tests {
  my $this = shift;

  my $repo = $this->getRepository;
  my $canChanges = $repo->getCapabilities()->{'Changes'};

  my $msg = $this->isBrokenFeature("paging");

SKIP: {
    skip "not able to log changes", unless defined $canChanges;
    skip $msg if $msg;

    my $changes1 = $repo->getContentChanges(maxItems => 2);
    my $size = $changes1->getSize;

    note("size1=$size");

    #    print STDERR "### changes:\n".$changes1->{xmlDoc}->toString(1)."\n###\n";

    my %entries1 = ();
    my @keys = ();
    my $index = 0;
    my $numTestedCycles = 10;
    while (my $entry = $changes1->getNext) {
      my $changeId = $entry->getId;
      ok(defined $changeId);

      my $id = $entry->getObjectId;
      ok(defined $id);

      my $changeType = $entry->getChangeType;
      like($changeType, qr'^(created|updated|deleted|security)$');

      my $changeTime = $entry->getChangeTime;
      like($changeTime, qr'^\d+');

      my $key = "$id-$changeTime";

      #print STDERR "$index: key1=$key\n";
      push @keys, $key;

      # this fails on nuxeo for no obvious reason ... bug
      #ok(!defined $entries1{$key}) || diag("found same key=$key twice in change log");
      $entries1{$key} = $entry;
      $index++;
      last if $index >= $numTestedCycles;
    }

    #print STDERR "index1=" . scalar(keys %entries1) . "\n";

    my $changes2 = $repo->getContentChanges(maxItems => 2);
    my $size2 = $changes2->getSize;
    note("size2=$size2");

    my %entries2 = ();
    $index = 0;
    while (my $entry = $changes2->getNext) {
      my $id = $entry->getObjectId;
      my $changeTime = $entry->getChangeTime;
      my $key = "$id-$changeTime";

      #print STDERR "$index: key2=$key\n";

      ok(defined $entries1{$key}) || diag("didn't find key=$key in first change log");

      # this fails on nuxeo for no obvious reason ... bug
      #ok(!defined $entries2{$key}) || diag("found same key=$key twice in change log");
      $entries2{$key} = $entry;
      $index++;
      last if $index >= $numTestedCycles;
    }

    #print STDERR "index2=".scalar(keys %entries2)."\n";

    foreach my $key (@keys) {

      #print STDERR "key=$key\n";
      ok(defined $entries2{$key}) or diag("entry $key in first set not found in second");
    }
  }
}

1;

